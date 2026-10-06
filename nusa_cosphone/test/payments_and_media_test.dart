// Contract tests for the systems ported from the web project: payments, the
// costume media gallery, pagination, and media URL retargeting.
//
// These lock in the shapes the Laravel API returns, so a change on either side
// that breaks the mobile client fails here first.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nusa_cosrent/data/api_client.dart';
import 'package:nusa_cosrent/data/cosrent_repository.dart';
import 'package:nusa_cosrent/data/models.dart';

/// A paginated Laravel envelope.
Map<String, Object?> _page(List<Object?> data, {int lastPage = 1}) =>
    <String, Object?>{
      'data': data,
      'meta': <String, Object?>{
        'current_page': 1,
        'last_page': lastPage,
        'total': data.length,
      },
    };

Map<String, Object?> _costume({
  int id = 1,
  List<String> images = const <String>[],
  List<String> videos = const <String>[],
  String? imageUrl,
  Map<String, Object?>? ownerBank,
}) => <String, Object?>{
  'id': id,
  'owner_id': 3,
  'name': 'Nebula Witch',
  'character_name': 'Luna',
  'category': 'Fantasy',
  'size': 'M',
  'color': 'Ungu',
  'description': 'Lengkap dengan mantle.',
  'image_url': imageUrl,
  'cover_image_url': imageUrl ?? (images.isEmpty ? null : images.first),
  'image_urls': images,
  'video_urls': videos,
  'image_count': images.length,
  'video_count': videos.length,
  'price_per_day': 85000,
  'stock': 3,
  'is_published': true,
  'is_available': true,
  'owner_bank': ownerBank,
};

Map<String, Object?> _order({
  int id = 10,
  String paymentMethod = 'pay_at_owner',
  String? paymentCode,
  bool hasProof = false,
  String? proofFilename,
  bool canViewProof = false,
}) => <String, Object?>{
  'id': id,
  'owner_id': 3,
  'customer_id': 7,
  'costume_id': 1,
  'status': 'pending',
  'quantity': 1,
  'rental_start': '2026-10-10',
  'rental_end': '2026-10-12',
  'requested_rental_start': '2026-10-10',
  'requested_rental_end': '2026-10-12',
  'duration_in_days': 3,
  'total_price': 255000,
  'payment_method': paymentMethod,
  'payment_code': paymentCode,
  'has_payment_proof': hasProof,
  'payment_proof_filename': proofFilename,
  'can_view_payment_proof': canViewProof,
};

/// Build a repository over a scripted backend.
Future<CosrentRepository> _repository(
  Future<http.Response> Function(http.Request request) handler,
) async {
  final client = ApiClient(
    baseUrl: 'http://localhost:8000/api/v1',
    httpClient: MockClient(handler),
    tokenStore: MemoryTokenStore(),
  );
  final repository = CosrentRepository(client);
  await repository.initialize();
  await repository.authenticate('customer@cosplaynusa.test', 'password');
  return repository;
}

http.Response _json(Object? payload, [int status = 200]) =>
    http.Response(jsonEncode(payload), status, headers: {
      'content-type': 'application/json',
    });

void main() {
  // `MultipartFile.fromPath` reads a file to measure it, so the upload tests
  // need bytes that actually exist.
  late Directory tempDir;
  late String receiptPath;
  late List<String> imagePaths;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cosrent_test');
    final sep = Platform.pathSeparator;
    receiptPath = '${tempDir.path}$sep${Platform.pathSeparator}receipt.png';
    await File(receiptPath).writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47, 9]);
    imagePaths = <String>[];
    for (var i = 0; i < 2; i++) {
      final path = '${tempDir.path}$sep${Platform.pathSeparator}image$i.png';
      await File(path).writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47, i]);
      imagePaths.add(path);
    }
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  group('payment', () {
    test('a cash booking sends the method and returns the payment code', () async {
      http.Request? booking;

      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
              'is_admin': false,
              'is_cosrent_owner': false,
            },
          });
        }
        booking = request;
        return _json(<String, Object?>{'data': _order(paymentCode: 'COSPAY-ABCD-1234')}, 201);
      });

      final result = await repository.createOrder(
        costumeId: 1,
        startDate: DateTime(2026, 10, 10),
        days: 3,
        paymentMethod: PaymentMethod.payAtOwner,
      );

      final body = jsonDecode(booking!.body) as Map<String, dynamic>;
      expect(body['payment_method'], 'pay_at_owner');
      expect(body['rental_start'], '2026-10-10');
      // Three days of use run from the pickup date, so the end date is derived.
      expect(body['rental_end'], '2026-10-12');
      // A cash booking must not smuggle an empty receipt field.
      expect(body.containsKey('payment_proof'), isFalse);
      expect(result?.paymentCode, 'COSPAY-ABCD-1234');
      expect(result!.isPaidAtOwner, isTrue);
      expect(result.hasPaymentProof, isFalse);
    });

    test('a bank transfer booking carries the receipt as multipart', () async {
      late http.Request booking;
      String? contentType;

      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        booking = request;
        contentType = request.headers['content-type'];
        return _json(
          <String, Object?>{
            'data': _order(
              paymentMethod: 'bank_transfer',
              hasProof: true,
              proofFilename: 'receipt.png',
              canViewProof: true,
            ),
          },
          201,
        );
      });

      final result = await repository.createOrder(
        costumeId: 1,
        startDate: DateTime(2026, 10, 10),
        days: 3,
        paymentMethod: PaymentMethod.bankTransfer,
        paymentProofPath: receiptPath,
      );

      expect(contentType, contains('multipart/form-data'));
      final raw = latin1.decode(booking.bodyBytes);
      expect(raw, contains('name="payment_method"'));
      expect(raw, contains('bank_transfer'));
      expect(raw, contains('name="payment_proof"'));
      expect(result!.isPaidByTransfer, isTrue);
      expect(result.paymentCode, isNull);
      expect(result.hasPaymentProof, isTrue);
      expect(result.canShowPaymentProof, isTrue);
    });

    test('a bank transfer without a receipt fails before the request', () async {
      var requests = 0;
      final repository = await _repository((request) async {
        requests++;
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        return _json(<String, Object?>{}, 500);
      });

      await expectLater(
        repository.createOrder(
          costumeId: 1,
          startDate: DateTime(2026, 10, 10),
          days: 3,
          paymentMethod: PaymentMethod.bankTransfer,
        ),
        throwsA(isA<ApiException>()),
      );
      // Only the login request went out; no half-built booking was attempted.
      expect(requests, 1);
    });

    test('the receipt is fetched from the endpoint the role owns', () async {
      final paths = <String>[];
      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        paths.add(request.url.path);
        return http.Response.bytes(
          Uint8List.fromList(<int>[1, 2, 3]),
          200,
          headers: const <String, String>{
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="transfer.pdf"',
          },
        );
      });

      final file = await repository.getPaymentProof(10);
      expect(paths.single, '/api/v1/customer/orders/10/payment-proof');
      expect(file.filename, 'transfer.pdf');
      expect(file.bytes, hasLength(3));
      // A PDF must not be handed to the image decoder.
      expect(file.isImage, isFalse);
    });

    test('bank details round-trip and stay private to the signed-in account', () {
      final owner = AppUser.fromMap(<String, Object?>{
        'id': 3,
        'name': 'Nadia',
        'email': 'owner@cosplaynusa.test',
        'role': 'owner',
        'is_cosrent_owner': true,
        'bank_details': <String, Object?>{
          'bank_name': 'Mandiri',
          'account_number': '1050021051887',
          'account_holder': 'Nadia',
          'is_complete': true,
        },
        'has_bank_account': true,
      });

      expect(owner.bankDetails.isComplete, isTrue);
      expect(owner.bankDetails.maskedAccountNumber, '1050 0210 5188 7');
      expect(owner.hasBankAccount, isTrue);

      // Another account is served with a null block.
      final customer = AppUser.fromMap(<String, Object?>{
        'id': 7,
        'name': 'Raka',
        'email': 'raka@cosplaynusa.test',
        'role': 'customer',
        'bank_details': null,
        'has_bank_account': false,
      });
      expect(customer.bankDetails.isEmpty, isTrue);
      expect(customer.hasBankAccount, isFalse);
    });

    test('an incomplete bank trio is rejected', () {
      expect(
        BankDetails(bankName: 'Mandiri', accountNumber: '', accountHolder: '')
            .isComplete,
        isFalse,
      );
      expect(BankDetails.empty.isComplete, isFalse);
    });
  });

  group('costume media', () {
    test('the gallery and counts are parsed', () async {
      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        return _json(
          _page(<Object?>[
            _costume(
              images: <String>[
                'https://cdn.test/storage/costumes/1/images/a.png',
                'https://cdn.test/storage/costumes/1/images/b.png',
              ],
              videos: <String>[
                'https://cdn.test/storage/costumes/1/videos/c.mp4',
              ],
            ),
          ]),
        );
      });

      final page = await repository.getCostumes();
      final costume = page.items.single;
      expect(costume.imageCount, 2);
      expect(costume.videoCount, 1);
      expect(costume.hasGallery, isTrue);
      expect(costume.galleryUrls, hasLength(3));
      // No explicit cover URL, so the first gallery image stands in.
      expect(costume.primaryImage, endsWith('/a.png'));
    });

    test('an upload sends indexed image fields', () async {
      late http.Request save;
      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        save = request;
        return _json(<String, Object?>{'data': _costume(id: 2)}, 201);
      });

      await repository.createCostume(
        Costume(
          id: 0,
          ownerId: 3,
          name: 'Nebula Witch',
          category: 'Fantasy',
          size: 'M',
          color: 'Ungu',
          description: '',
          price: 85000,
          extraPricePerDay: 25000,
          isAvailable: true,
        ),
        imagePaths: imagePaths,
      );

      expect(save.headers['content-type'], contains('multipart/form-data'));
      final raw = latin1.decode(save.bodyBytes);
      expect(raw, contains('name="images[0]"'));
      expect(raw, contains('name="images[1]"'));
      // A listing without an explicit cover sends an empty field, not null.
      expect(raw, contains('name="image_url"'));
      expect(raw, contains('name="is_published"'));
    });

    test('a removal is reduced to the stored path', () async {
      late http.Request save;
      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        save = request;
        return _json(<String, Object?>{'data': _costume(id: 5)});
      });

      await repository.updateCostume(
        Costume(
          id: 5,
          ownerId: 3,
          name: 'Nebula Witch',
          category: 'Fantasy',
          size: 'M',
          color: 'Ungu',
          description: '',
          price: 85000,
          extraPricePerDay: 25000,
          isAvailable: true,
        ),
        removeImageUrls: <String>[
          'https://nusa_rental_cosplay.test/storage/costumes/5/images/a.png',
        ],
      );

      // The server intersects removals against stored paths, so a full URL
      // would silently remove nothing.
      final raw = latin1.decode(save.bodyBytes);
      expect(raw, contains('costumes/5/images/a.png'));
      expect(raw, isNot(contains('https://nusa_rental_cosplay.test')));
    });
  });

  group('pagination', () {
    test('page metadata is read and exposed', () async {
      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        return _json(_page(<Object?>[_order(id: 1), _order(id: 2)], lastPage: 3));
      });

      final page = await repository.getOrders();
      expect(page.items, hasLength(2));
      expect(page.currentPage, 1);
      expect(page.lastPage, 3);
      expect(page.hasMore, isTrue);
    });

    test('the last page reports no more results', () async {
      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        return _json(_page(<Object?>[_order(id: 9)], lastPage: 1));
      });

      final page = await repository.getOrders();
      expect(page.hasMore, isFalse);
    });

    test('an unpaginated list still parses', () {
      final page = Paginated.fromJson<_OrderShim>(
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'id': 1},
          ],
        },
        (_) => const _OrderShim(),
      );
      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
    });
  });

  group('media url retargeting', () {
    test('a foreign host is rewritten onto the active api host', () {
      final client = ApiClient(
        baseUrl: 'http://192.168.1.10:8000/api/v1',
        httpClient: MockClient((_) async => _json(const <String, Object?>{})),
        tokenStore: MemoryTokenStore(),
      );

      expect(
        client.normalizeMediaUrl(
          'https://nusa_rental_cosplay.test/storage/costumes/1/images/a.png',
        ),
        'http://192.168.1.10:8000/storage/costumes/1/images/a.png',
      );
      // A relative path has nothing to rewrite.
      expect(client.normalizeMediaUrl('/storage/a.png'), '/storage/a.png');
      expect(client.normalizeMediaUrl(null), isNull);
      expect(client.normalizeMediaUrl(''), '');
    });

    test('a url already on the right host is left alone', () {
      final client = ApiClient(
        baseUrl: 'http://192.168.1.10:8000/api/v1',
        httpClient: MockClient((_) async => _json(const <String, Object?>{})),
        tokenStore: MemoryTokenStore(),
      );
      const url = 'http://192.168.1.10:8000/storage/a.png';
      expect(client.normalizeMediaUrl(url), url);
    });

    test('catalog media is retargeted when the list is parsed', () async {
      final repository = await _repository((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return _json(<String, Object?>{
            'token': 'tok',
            'user': <String, Object?>{
              'id': 7,
              'name': 'Raka',
              'email': 'raka@cosplaynusa.test',
              'role': 'customer',
            },
          });
        }
        return _json(
          _page(<Object?>[
            _costume(
              images: <String>[
                'https://nusa_rental_cosplay.test/storage/costumes/1/images/a.png',
              ],
              ownerBank: <String, Object?>{
                'bank_name': 'Mandiri',
                'account_number': '1050021051887',
                'account_holder': 'Nadia',
                'is_complete': true,
              },
            ),
          ]),
        );
      });

      final costume = (await repository.getCostumes()).items.single;
      expect(
        costume.imageUrls.single,
        'http://localhost:8000/storage/costumes/1/images/a.png',
      );
      // The supplier's account survives the rewrite untouched.
      expect(costume.ownerBank.bankName, 'Mandiri');
      expect(costume.ownerBank.isComplete, isTrue);
    });
  });
}

/// A stand-in with no behaviour, only used to prove the parser is generic.
class _OrderShim {
  const _OrderShim();
}