<?php

namespace App\Http\Controllers\Customer;

use App\Http\Controllers\Controller;
use App\Models\Costume;
use Illuminate\View\View;

class CostumeController extends Controller
{
    /**
     * Show the product detail page for a published costume.
     */
    public function show(Costume $availableCostume): View
    {
        $availableCostume->load('owner:id,name');

        return view('customer.costumes.show', [
            'availableCostume' => $availableCostume,
            'gallery' => $availableCostume->imageUrls(),
            'videos' => $availableCostume->videoUrls(),
        ]);
    }
}
