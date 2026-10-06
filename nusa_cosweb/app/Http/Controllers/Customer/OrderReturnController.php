<?php

namespace App\Http\Controllers\Customer;

use App\Actions\ReturnRentalOrder as ReturnRentalOrderAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\ReturnRentalOrderRequest;
use App\Models\RentalOrder;
use Illuminate\Http\RedirectResponse;

class OrderReturnController extends Controller
{
    /**
     * Submit the customer's costume return.
     */
    public function store(
        ReturnRentalOrderRequest $request,
        RentalOrder $customerRentalOrder,
        ReturnRentalOrderAction $returnRentalOrder,
    ): RedirectResponse {
        $returnRentalOrder->handle(
            $customerRentalOrder,
            $request->validated('return_note'),
        );

        return redirect()
            ->route('dashboard')
            ->with('status', __('customer.return.submitted'));
    }
}
