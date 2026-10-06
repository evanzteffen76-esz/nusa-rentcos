<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Actions\ReportRentalIssue;
use App\Actions\ResolveRentalIssue as ResolveRentalIssueAction;
use App\Enums\RentalIssueType;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Owner\ReportStainRequest;
use App\Http\Requests\Api\V1\Owner\ResolveIssueRequest;
use App\Http\Resources\RentalIssueResource;
use App\Http\Resources\RentalOrderResource;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Throwable;

class IssueController extends Controller
{
    /**
     * List all issue reports for the authenticated owner.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', RentalOrder::class);
        $query = RentalIssue::query()
            ->whereHas('rentalOrder', fn ($order) => $order->where('owner_id', $request->user()->id))
            ->with(['reporter', 'rentalOrder.customer', 'rentalOrder.costume.owner'])
            ->latest('id');
        $status = $request->input('status');

        if ($status !== null && $status !== 'all') {
            abort_unless(in_array($status, ['open', 'resolved'], true), 422, 'The selected issue status is invalid.');
            $query->where('status', $status);
        }

        return RentalIssueResource::collection(
            $query->paginate(min(50, max(1, $request->integer('per_page', 50)))),
        );
    }

    /**
     * Report a stain and attach a fine.
     */
    public function store(
        ReportStainRequest $request,
        RentalOrder $ownerOrder,
        ReportRentalIssue $reportRentalIssue,
    ): JsonResponse {
        Gate::authorize('reportStain', $ownerOrder);
        $evidencePath = $request->hasFile('evidence')
            ? $request->file('evidence')->store('rental-issues/stains', 'local')
            : null;

        try {
            $reportRentalIssue->handle(
                $ownerOrder,
                RentalIssueType::Stain,
                $request->user(),
                $request->validated('description'),
                $evidencePath,
                (int) $request->validated('fine_amount'),
            );
        } catch (Throwable $exception) {
            if ($evidencePath !== null) {
                Storage::disk('local')->delete($evidencePath);
            }

            throw $exception;
        }

        $ownerOrder->refresh()->load(['customer', 'costume', 'issue.reporter']);

        return response()->json([
            'message' => 'Stain report submitted successfully.',
            'data' => new RentalOrderResource($ownerOrder),
        ], 201);
    }

    /**
     * Resolve a fine or replacement issue.
     */
    public function resolve(
        ResolveIssueRequest $request,
        RentalOrder $ownerOrder,
        RentalIssue $ownerIssue,
        ResolveRentalIssueAction $resolveRentalIssue,
    ): JsonResponse {
        Gate::authorize('resolve', $ownerIssue);
        $resolveRentalIssue->handle(
            $ownerIssue,
            $request->boolean('fine_paid'),
            $request->boolean('replacement_received'),
            $request->validated('resolution_note'),
        );

        $ownerOrder->refresh()->load(['customer', 'costume', 'issue.reporter']);

        return response()->json([
            'message' => 'Issue resolved successfully.',
            'data' => new RentalOrderResource($ownerOrder),
        ]);
    }

    /**
     * Download private issue evidence.
     */
    public function evidence(
        RentalOrder $ownerOrder,
        RentalIssue $ownerIssue,
    ): StreamedResponse {
        Gate::authorize('view', $ownerIssue);
        abort_if(blank($ownerIssue->evidence_path), 404);

        return Storage::disk('local')->download(
            $ownerIssue->evidence_path,
            basename($ownerIssue->evidence_path),
        );
    }
}
