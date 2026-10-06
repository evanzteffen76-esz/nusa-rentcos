<?php

namespace App\Http\Controllers\Owner;

use App\Actions\ReportRentalIssue;
use App\Actions\ResolveRentalIssue;
use App\Enums\RentalIssueType;
use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\ReportStainRequest;
use App\Http\Requests\Owner\ResolveRentalIssueRequest;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Throwable;

class OrderIssueController extends Controller
{
    /**
     * Store an owner stain report and fine amount.
     */
    public function store(
        ReportStainRequest $request,
        RentalOrder $ownerRentalOrder,
        ReportRentalIssue $reportRentalIssue,
    ): RedirectResponse {
        $evidencePath = $request->file('evidence')->store('rental-issues/stains', 'local');

        try {
            $reportRentalIssue->handle(
                $ownerRentalOrder,
                RentalIssueType::Stain,
                $request->user(),
                $request->validated('description'),
                $evidencePath,
                (int) $request->validated('fine_amount'),
            );
        } catch (Throwable $exception) {
            Storage::disk('local')->delete($evidencePath);

            throw $exception;
        }

        return redirect()
            ->route('cosrent-owner.orders.show', $ownerRentalOrder)
            ->with('status', __('owner.issues.stain_submitted'));
    }

    /**
     * Resolve a stain fine or lost-costume replacement.
     */
    public function resolve(
        ResolveRentalIssueRequest $request,
        RentalOrder $ownerRentalOrder,
        RentalIssue $rentalIssue,
        ResolveRentalIssue $resolveRentalIssue,
    ): RedirectResponse {
        $resolveRentalIssue->handle(
            $rentalIssue,
            $request->boolean('fine_paid'),
            $request->boolean('replacement_received'),
            $request->validated('resolution_note'),
        );

        return redirect()
            ->route('cosrent-owner.orders.show', $ownerRentalOrder)
            ->with('status', __('owner.issues.resolved'));
    }

    /**
     * Download private evidence for an issue after owner authorization.
     */
    public function evidence(
        RentalOrder $ownerRentalOrder,
        RentalIssue $rentalIssue,
    ): StreamedResponse {
        Gate::authorize('view', $rentalIssue);

        abort_if(blank($rentalIssue->evidence_path), 404);

        return Storage::disk('local')->download(
            $rentalIssue->evidence_path,
            basename($rentalIssue->evidence_path),
        );
    }
}
