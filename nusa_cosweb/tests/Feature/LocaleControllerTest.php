<?php

test('uses Indonesian as the default application locale', function (): void {
    $this->get('/')
        ->assertOk()
        ->assertSee(__('site.hero.badge'));
});

test('renders all supported language options', function (): void {
    $this->get('/')
        ->assertOk()
        ->assertSee('Bahasa Indonesia')
        ->assertSee('English')
        ->assertSee('简体中文')
        ->assertSee('日本語')
        ->assertSee('한국어');
});

test('switches the locale and redirects to the requested page', function (): void {
    $response = $this->post(route('language.switch'), [
        'locale' => 'ja',
        'redirect' => '/',
    ]);

    $response
        ->assertRedirect('/')
        ->assertSessionHas('locale', 'ja');

    $this->get('/')
        ->assertOk()
        ->assertSee(__('site.hero.badge'));
});

test('uses the browser language when no locale has been selected', function (): void {
    $this->withHeader('Accept-Language', 'ko-KR,ko;q=0.9')
        ->get('/')
        ->assertOk()
        ->assertSee(__('site.hero.badge'));
});

test('rejects unsupported locales', function (): void {
    $this->post(route('language.switch'), [
        'locale' => 'fr',
    ])->assertNotFound();
});
