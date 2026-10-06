import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:nusa_cosrent/data/api_client.dart';
import 'package:nusa_cosrent/data/cosrent_repository.dart';
import 'package:nusa_cosrent/data/models.dart';

void main() {
  test('user roles map to their role landing areas', () {
    const customer = AppUser(
      id: 1,
      name: 'Customer',
      email: 'customer@example.test',
      role: 'customer',
      isAdmin: false,
      isCosrentOwner: false,
    );
    const owner = AppUser(
      id: 2,
      name: 'Owner',
      email: 'owner@example.test',
      role: 'owner',
      isAdmin: false,
      isCosrentOwner: true,
    );
    const admin = AppUser(
      id: 3,
      name: 'Admin',
      email: 'admin@example.test',
      role: 'admin',
      isAdmin: true,
      isCosrentOwner: false,
    );

    expect(customer.area, UserArea.customer);
    expect(owner.area, UserArea.owner);
    expect(admin.area, UserArea.admin);
  });

  test(
    'rental order parsing tolerates missing dates and maps capabilities',
    () {
      final order = RentalOrder.fromMap({
        'id': 9,
        'status': 'approved',
        'rental_start': null,
        'rental_end': null,
        'requested_rental_start': '2026-10-01',
        'requested_rental_end': '2026-10-03',
        'can_return': false,
        'can_report_lost': true,
        'issue': {
          'id': 3,
          'rental_order_id': 9,
          'type': 'stain',
          'status': 'open',
          'description': 'Noda',
        },
      });

      expect(order.startDate, DateTime(2026, 10, 1));
      expect(order.endDate, DateTime(2026, 10, 3));
      expect(order.canReturn, isFalse);
      expect(order.canReportLost, isFalse);
      expect(order.hasOpenIssue, isTrue);
    },
  );

  test(
    'API repository authenticates, persists token, and maps catalog',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/auth/login')) {
          return _jsonResponse({
            'token': 'demo-token',
            'token_type': 'Bearer',
            'user': {
              'id': 1,
              'name': 'Raka Pradana',
              'username': 'customer',
              'email': 'customer@cosplaynusa.test',
              'role': 'customer',
              'is_admin': false,
              'is_cosrent_owner': false,
            },
          });
        }
        if (request.url.path.endsWith('/costumes')) {
          return _jsonResponse({
            'data': [
              {
                'id': 7,
                'owner_id': 2,
                'owner': {'id': 2, 'name': 'Nadia Cosrent'},
                'name': 'Nebula Witch',
                'character_name': 'Luna',
                'category': 'Fantasy',
                'size': 'M',
                'color': 'Purple',
                'description': 'A complete set.',
                'image_url': null,
                'price_per_day': 85000,
                'stock': 3,
                'is_published': true,
                'is_available': true,
              },
            ],
          });
        }
        return _jsonResponse({}, 404);
      });
      final repository = CosrentRepository(
        ApiClient(
          baseUrl: 'http://localhost:8000/api/v1',
          httpClient: client,
          tokenStore: MemoryTokenStore(),
        ),
      );
      await repository.initialize();

      final user = await repository.authenticate(
        'customer@cosplaynusa.test',
        'password',
      );
      expect(user?.role, 'customer');
      expect(user?.username, 'customer');
      expect(repository.client.hasToken, isTrue);
      final loginBody = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(loginBody['login'], 'customer@cosplaynusa.test');
      expect(loginBody.containsKey('email'), isFalse);

      final costumes = (await repository.getCostumes()).items;
      expect(costumes, hasLength(1));
      expect(costumes.single.name, 'Nebula Witch');
      expect(costumes.single.color, 'Purple');
      expect(requests.last.headers['authorization'], 'Bearer demo-token');
    },
  );

  test('API client probes fallback emulator hosts', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.host == 'secondary.test') {
        return _jsonResponse({'status': 'ok'});
      }
      return _jsonResponse({'status': 'degraded'}, 503);
    });
    final api = ApiClient(
      baseUrl: 'http://primary.test:8000/api/v1',
      fallbackBaseUrls: ['http://secondary.test:8000/api/v1'],
      autoResolve: true,
      httpClient: client,
      tokenStore: MemoryTokenStore(),
    );

    await api.resolveEndpoint();

    expect(api.baseUrl, 'http://secondary.test:8000/api/v1');
    expect(requests.map((request) => request.url.host), [
      'primary.test',
      'secondary.test',
    ]);
  });

  test('API repository sends server-owned booking fields', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/auth/login')) {
        return _jsonResponse({
          'token': 'demo-token',
          'user': {
            'id': 1,
            'name': 'Customer',
            'email': 'customer@cosplaynusa.test',
            'role': 'customer',
          },
        });
      }
      if (request.url.path.contains('/orders')) {
        return _jsonResponse({
          'data': {
            'id': 10,
            'status': 'pending',
            'quantity': 1,
            'rental_start': '2026-10-01',
            'rental_end': '2026-10-03',
            'total_price': 255000,
          },
        }, 201);
      }
      return _jsonResponse({}, 404);
    });
    final repository = CosrentRepository(
      ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        httpClient: client,
        tokenStore: MemoryTokenStore(),
      ),
    );
    await repository.initialize();
    await repository.authenticate('customer@cosplaynusa.test', 'password');
    await repository.createOrder(
      costumeId: 7,
      startDate: DateTime(2026, 10, 1),
      days: 3,
      notes: 'Event',
    );

    final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(body['rental_start'], '2026-10-01');
    expect(body['rental_end'], '2026-10-03');
    expect(body['customer_note'], 'Event');
    expect(body.containsKey('total_price'), isFalse);
    // The server derives the length from the two dates, so the client must
    // not send a competing day count.
    expect(body.containsKey('rental_days'), isFalse);
  });
}

http.Response _jsonResponse(Object payload, [int status = 200]) {
  return http.Response(
    jsonEncode(payload),
    status,
    headers: {'content-type': 'application/json'},
  );
}
