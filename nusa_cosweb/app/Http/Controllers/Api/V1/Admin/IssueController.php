<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\ResolveRentalIssue as ResolveRentalIssueAction;
use App\Http\Controllers\Controller;
use App\Http\Resources\RentalIssueResource;
use App\Models\RentalIssue;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\ValidationException;

class IssueController extends Controller
{
    /**
     * List all issue reports for the administration console.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = RentalIssue::query()
            ->with(['reporter', 'rentalOrder.customer', 'rentalOrder.costume.owner'])
            ->latest('id');
        $status = $request->input('status');

        if ($status !== null && $status !== 'all') {
            if (! in_array($status, ['open', 'resolved'], true)) {
                throw ValidationException::withMessages([
                    'status' => 'The selected issue status is invalid.',
                ]);
            }
            $query->where('status', $status);
        }

        return RentalIssueResource::collection(
            $query->paginate(min(100, max(1, $request->integer('per_page', 50)))),
        );
    }

    /**
     * Resolve an issue after support has verified payment or replacement.
     */
    public function resolve(
        Request $request,
        RentalIssue $issue,
        ResolveRentalIssueAction $resolveRentalIssue,
    ): JsonResponse {
        $data = $request->validate([
            'fine_paid' => ['sometimes', 'boolean'],
            'replacement_received' => ['sometimes', 'boolean'],
            'resolution_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $resolved = $resolveRentalIssue->handle(
            $issue,
            $request->boolean('fine_paid'),
            $request->boolean('replacement_received'),
            $data['resolution_note'] ?? null,
        );

        return response()->json([
            'message' => 'Issue resolved successfully.',
            'data' => new RentalIssueResource(
                $resolved->load(['reporter', 'rentalOrder.customer', 'rentalOrder.costume.owner']),
            ),
        ]);
    }

    /**
     * Delete an issue for administrative cleanup.
     */
    public function destroy(RentalIssue $issue): JsonResponse
    {
        $issue->delete();

        return response()->json(['message' => 'Issue deleted successfully.']);
    }
}
