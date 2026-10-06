<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Requests\Api\V1\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a customer or owner and issue an API token.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();

        $user = User::query()->create([
            'name' => $data['name'],
            'username' => $this->resolveUsername($data),
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'is_cosrent_owner' => ($data['account_type'] ?? 'customer') === 'cosrent_owner',
        ]);

        return $this->tokenResponse($user, $data['device_name'] ?? 'flutter', 201);
    }

    /**
     * Authenticate credentials and issue an API token.
     *
     * @throws ValidationException
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $data = $request->validated();
        $login = $data['login'];
        $user = User::query()
            ->where(function ($query) use ($login): void {
                $query->where('email', $login)
                    ->orWhere('username', $login);
            })
            ->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => trans('auth.failed'),
            ]);
        }

        return $this->tokenResponse($user, $data['device_name'] ?? 'flutter');
    }

    /**
     * Return the currently authenticated user.
     */
    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'data' => new UserResource($request->user()),
        ]);
    }

    /**
     * Revoke the current API token.
     */
    public function logout(Request $request): JsonResponse
    {
        $token = $request->user()->currentAccessToken();

        if ($token !== null) {
            $token->delete();
        }

        return response()->json([
            'message' => 'Token revoked successfully.',
        ]);
    }

    /**
     * Update the authenticated user's own profile.
     */
    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();
        $updates = [];

        if (array_key_exists('name', $data)) {
            $updates['name'] = trim($data['name']);
        }

        if (array_key_exists('email', $data)) {
            $updates['email'] = $data['email'];
        }

        if (filled($data['username'] ?? null)) {
            $updates['username'] = $data['username'];
        }

        if (filled($data['password'] ?? null)) {
            $updates['password'] = Hash::make($data['password']);
        }

        // Bank details are only meaningful for an owner, and only saved when
        // the whole trio arrives so a partial form never overwrites a good
        // account with a broken one.
        if ($user->isCosrentOwner() && array_key_exists('bank_name', $data)) {
            $updates = array_merge($updates, $this->resolveBankDetails($data));
        }

        if ($updates !== []) {
            $user->update($updates);
        }

        return response()->json([
            'data' => new UserResource($user->fresh()),
        ]);
    }

    /**
     * Build the bank updates from a complete trio, or clear them.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, string|null>
     */
    private function resolveBankDetails(array $data): array
    {
        $name = trim((string) ($data['bank_name'] ?? ''));
        $number = trim((string) ($data['bank_account_number'] ?? ''));
        $holder = trim((string) ($data['bank_account_holder'] ?? ''));

        // The request rules already rejected a partial trio, so reaching an
        // empty value here means the owner deliberately cleared the account.
        return [
            'bank_name' => $name !== '' ? $name : null,
            'bank_account_number' => $number !== '' ? $number : null,
            'bank_account_holder' => $holder !== '' ? $holder : null,
        ];
    }

    /**
     * Permanently delete the authenticated user's own account.
     *
     * Deleting cascades to the user's costumes, rental orders and reported
     * issues, so active rentals are blocked first: silently discarding a
     * running booking would strand the customer.
     */
    public function destroyAccount(Request $request): JsonResponse
    {
        $user = $request->user();
        $password = (string) $request->validate([
            'password' => ['required', 'string'],
        ])['password'];

        if (! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'password' => 'Password salah.',
            ]);
        }

        $activeOrders = RentalOrder::query()
            ->where(function ($query) use ($user): void {
                $query->where('owner_id', $user->id)
                    ->orWhere('customer_id', $user->id);
            })
            ->whereIn('status', ['pending', 'approved'])
            ->count();

        if ($activeOrders > 0) {
            throw ValidationException::withMessages([
                'account' => 'Selesaikan proses sewa yang sedang berjalan sebelum menghapus akun.',
            ]);
        }

        if ($user->isAdmin() && User::query()->where('is_admin', true)->count() <= 1) {
            throw ValidationException::withMessages([
                'account' => 'Akun admin terakhir tidak dapat dihapus.',
            ]);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'message' => 'Account deleted successfully.',
        ]);
    }

    /**
     * Resolve a unique username for registrations that do not provide one.
     *
     * @param  array<string, mixed>  $data
     */
    private function resolveUsername(array $data): string
    {
        $source = $data['username'] ?? Str::before($data['email'], '@');
        $username = Str::lower(trim((string) $source));
        $username = preg_replace('/[^a-z0-9._-]/', '', $username) ?: 'user';
        $username = substr($username, 0, 50);

        if (User::query()->where('username', $username)->exists()) {
            $username = substr($username, 0, 45).'-'.Str::lower(Str::random(4));
        }

        return $username;
    }

    /**
     * Issue a Sanctum token and return the mobile session payload.
     */
    private function tokenResponse(User $user, string $deviceName, int $status = 200): JsonResponse
    {
        $ability = $user->isAdmin() ? 'admin' : ($user->isCosrentOwner() ? 'owner' : 'customer');
        $token = $user->createToken($deviceName, [$ability]);

        return response()->json([
            'token' => $token->plainTextToken,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
        ], $status);
    }
}
