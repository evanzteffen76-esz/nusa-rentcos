<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    /**
     * List users for the mobile administration console.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = User::query()->latest('id');
        $search = trim((string) $request->input('search', ''));

        if ($search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder->where('name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        return UserResource::collection(
            $query->paginate(min(100, max(1, $request->integer('per_page', 50)))),
        );
    }

    /**
     * Create a user with an explicit role.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $this->validatedUser($request);
        $role = $data['role'] ?? 'customer';
        $user = User::query()->create([
            'name' => trim($data['name']),
            'username' => $this->resolveUsername($data),
            'email' => strtolower(trim($data['email'])),
            'password' => Hash::make($data['password']),
            'is_admin' => $role === 'admin',
            'is_cosrent_owner' => $role === 'owner',
        ]);

        return (new UserResource($user))->response()->setStatusCode(201);
    }

    /**
     * Update a user's profile, role, or optional password.
     */
    public function update(Request $request, User $user): UserResource
    {
        $data = $this->validatedUser($request, $user, false);
        $role = $data['role'] ?? null;
        $updates = [
            'name' => trim($data['name']),
            'email' => strtolower(trim($data['email'])),
        ];

        if (filled($data['username'] ?? null)) {
            $updates['username'] = strtolower(trim($data['username']));
        } elseif ($user->username === null) {
            $updates['username'] = $this->resolveUsername($data + ['email' => $user->email]);
        }

        if ($role !== null) {
            $updates['is_admin'] = $role === 'admin';
            $updates['is_cosrent_owner'] = $role === 'owner';
        }

        if (filled($data['password'] ?? null)) {
            $updates['password'] = Hash::make($data['password']);
        }

        $user->update($updates);

        return new UserResource($user->fresh());
    }

    /**
     * Delete a user while protecting the current administrator account.
     */
    public function destroy(Request $request, User $user): JsonResponse
    {
        if ($request->user()->is($user)) {
            throw ValidationException::withMessages([
                'user' => 'Akun admin yang sedang digunakan tidak dapat dihapus.',
            ]);
        }

        $user->delete();

        return response()->json(['message' => 'User deleted successfully.']);
    }

    /**
     * Validate a user payload.
     *
     * @return array<string, mixed>
     */
    private function validatedUser(Request $request, ?User $user = null, bool $passwordRequired = true): array
    {
        $userId = $user?->getKey();
        $passwordRules = $passwordRequired
            ? ['required', 'string', 'min:6', 'confirmed']
            : ['nullable', 'string', 'min:6', 'confirmed'];

        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'username' => [
                'nullable',
                'string',
                'min:3',
                'max:50',
                'regex:/^[a-z0-9._-]+$/',
                Rule::unique(User::class, 'username')->ignore($userId),
            ],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique(User::class, 'email')->ignore($userId),
            ],
            'password' => $passwordRules,
            'role' => ['nullable', Rule::in(['customer', 'owner', 'admin'])],
        ]);
    }

    /**
     * Create a unique username when an administrator creates a user without one.
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
}
