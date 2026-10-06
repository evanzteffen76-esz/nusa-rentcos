<?php

namespace App\Http\Controllers\Customer;

use App\Actions\ReportRentalIssue;
use App\Enums\RentalIssueType;
use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\ReportLostCostumeRequest;
use App\Models\RentalOrder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Throwable;

class OrderIssueController extends Controller
{
    /**
     * Show the lost-costume report form.
     */
    public function create(RentalOrder $customerRentalOrder): View
    {
        Gate::authorize('reportLostCostume', $customerRentalOrder);

        return view('customer.issues.create', compact('customerRentalOrder'));
    }

    /**
     * Store a lost-costume report and replacement proof.
     */
    public function store(
        ReportLostCostumeRequest $request,
        RentalOrder $customerRentalOrder,
        ReportRentalIssue $reportRentalIssue,
    ): RedirectResponse {
        $evidencePath = $request->file('replacement_proof')->store(
            'rental-issues/replacements',
            'local',
        );

        try {
            $reportRentalIssue->handle(
                $customerRentalOrder,
                RentalIssueType::Lost,
                $request->user(),
                $request->validated('description'),
                $evidencePath,
                0,
                (int) $request->validated('replacement_cost'),
            );
        } catch (Throwable $exception) {
            Storage::disk('local')->delete($evidencePath);

            throw $exception;
        }

        return redirect()
            ->route('dashboard')
            ->with('status', __('customer.issues.lost_submitted'));
    }
}
