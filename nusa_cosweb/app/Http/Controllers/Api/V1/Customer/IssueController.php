<?php

namespace App\Http\Controllers\Api\V1\Customer;

use App\Actions\ReportRentalIssue;
use App\Enums\RentalIssueType;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Customer\ReportLostRequest;
use App\Http\Resources\RentalOrderResource;
use App\Models\RentalOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Throwable;

class IssueController extends Controller
{
    /**
     * Report a lost costume and submit replacement proof.
     */
    public function store(
        ReportLostRequest $request,
        RentalOrder $customerOrder,
        ReportRentalIssue $reportRentalIssue,
    ): JsonResponse {
        Gate::authorize('reportLostCostume', $customerOrder);
        $evidencePath = $request->hasFile('replacement_proof')
            ? $request->file('replacement_proof')->store('rental-issues/replacements', 'local')
            : null;

        try {
            $reportRentalIssue->handle(
                $customerOrder,
                RentalIssueType::Lost,
                $request->user(),
                $request->validated('description'),
                $evidencePath,
                0,
                (int) $request->validated('replacement_cost'),
            );
        } catch (Throwable $exception) {
            if ($evidencePath !== null) {
                Storage::disk('local')->delete($evidencePath);
            }

            throw $exception;
        }

        $customerOrder->refresh()->load(['costume.owner', 'issue.reporter']);

        return response()->json([
            'message' => 'Lost costume report submitted successfully.',
            'data' => new RentalOrderResource($customerOrder),
        ], 201);
    }
}
