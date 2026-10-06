<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class LocaleController extends Controller
{
    /**
     * Store the selected application locale.
     */
    public function __invoke(Request $request): RedirectResponse
    {
        $locale = $request->string('locale')->toString();

        abort_unless(array_key_exists($locale, config('locales.supported', [])), 404);

        $request->session()->put('locale', $locale);

        $redirectPath = $request->string('redirect')->toString();

        if (! str_starts_with($redirectPath, '/') || str_starts_with($redirectPath, '//') || str_contains($redirectPath, '\\')) {
            $redirectPath = '/';
        }

        return redirect()->to($redirectPath);
    }
}
