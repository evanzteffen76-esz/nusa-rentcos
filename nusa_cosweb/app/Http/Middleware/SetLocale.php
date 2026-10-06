<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

class SetLocale
{
    /**
     * Apply the user's selected or browser-preferred locale.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $supportedLocales = array_keys(config('locales.supported', []));
        $locale = $request->session()->get('locale');

        if (! in_array($locale, $supportedLocales, true)) {
            $locale = $this->preferredLocale($request, $supportedLocales);
        }

        App::setLocale($locale);

        return $next($request);
    }

    /**
     * Resolve a supported locale from the request headers.
     *
     * @param  list<string>  $supportedLocales
     */
    private function preferredLocale(Request $request, array $supportedLocales): string
    {
        $defaultLocale = config('locales.default', 'id');

        foreach (explode(',', $request->header('Accept-Language', '')) as $languageRange) {
            $language = strtolower(trim(explode(';', $languageRange)[0]));
            $baseLanguage = explode('-', $language)[0];

            if (in_array($baseLanguage, $supportedLocales, true)) {
                return $baseLanguage;
            }
        }

        return in_array($defaultLocale, $supportedLocales, true) ? $defaultLocale : 'id';
    }
}
