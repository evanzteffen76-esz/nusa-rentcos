<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class OrderController extends Controller
{
    /**
     * Show the payment proof the customer submitted for their own order.
     */
    public function paymentProof(RentalOrder $customerRentalOrder): StreamedResponse
    {
        Gate::authorize('viewPaymentProof', $customerRentalOrder);

        abort_if(blank($customerRentalOrder->payment_proof_path), 404);

        return Storage::disk('local')->download(
            $customerRentalOrder->payment_proof_path,
            basename($customerRentalOrder->payment_proof_path),
        );
    }
}
