import 'package:flutter_test/flutter_test.dart';

import 'package:appsecurity/core/models/user.dart';
import 'package:appsecurity/core/models/resident.dart';
import 'package:appsecurity/core/models/booking.dart';
import 'package:appsecurity/core/models/access.dart';

void main() {
  group('User.fromJson', () {
    test('parsea campos básicos y rol', () {
      final user = User.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'firstName': 'Ana',
        'lastName': 'Lopez',
        'phone': null,
        'avatarUrl': null,
        'role': 'RESIDENT',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
      expect(user.fullName, 'Ana Lopez');
      expect(user.role, UserRole.resident);
    });

    test('parsea unit y residentStatus', () {
      final user = User.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'firstName': 'Ana',
        'lastName': 'Lopez',
        'role': 'COMMITTEE',
        'residentStatus': 'ACTIVE',
        'unit': {'id': 'unit-1', 'number': 'A-1', 'block': 'A'},
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
      expect(user.residentStatus, 'ACTIVE');
      expect(user.unit!.displayNumber, 'A-A-1');
    });
  });

  group('Visitor.fromJson', () {
    test('parsea visitante con accesos', () {
      final visitor = Visitor.fromJson({
        'id': 'v1',
        'firstName': 'Maria',
        'lastName': 'Perez',
        'phone': '555-0000',
        'isRecurring': true,
        'vehiclePlate': 'ABC-123',
        'accesses': [
          {
            'id': 'a1',
            'type': 'VISITOR',
            'status': 'APPROVED',
            'entryTime': '2026-01-01T10:00:00.000Z',
            'createdAt': '2026-01-01T09:00:00.000Z',
          }
        ],
      });
      expect(visitor.fullName, 'Maria Perez');
      expect(visitor.isRecurring, isTrue);
      expect(visitor.accesses.length, 1);
      expect(visitor.accesses.first.status, AccessStatus.approved);
    });
  });

  group('Booking.fromJson', () {
    test('parsea reserva con amenity y unit', () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'amenityId': 'am1',
        'amenity': {'id': 'am1', 'name': 'Alberca', 'pricePerHour': 100},
        'unitId': 'unit-1',
        'unit': {'id': 'unit-1', 'number': '1', 'block': 'A'},
        'userId': 'u1',
        'startTime': '2026-01-01T10:00:00.000Z',
        'endTime': '2026-01-01T11:00:00.000Z',
        'status': 'confirmed',
        'totalPrice': 100,
        'guestsCount': 4,
        'createdAt': '2026-01-01T09:00:00.000Z',
      });
      expect(booking.amenity.name, 'Alberca');
      expect(booking.status, BookingStatus.confirmed);
      expect(booking.canCancel, isTrue);
      expect(booking.formattedPrice, r'$100.00 MXN');
    });

    test('marca no cancelable cuando está completada', () {
      final booking = Booking.fromJson({
        'id': 'b2',
        'amenityId': 'am1',
        'amenity': {'id': 'am1', 'name': 'Gym', 'pricePerHour': 50},
        'unitId': 'unit-1',
        'unit': {'id': 'unit-1', 'number': '1'},
        'userId': 'u1',
        'startTime': '2026-01-02T10:00:00.000Z',
        'endTime': '2026-01-02T11:00:00.000Z',
        'status': 'completed',
        'totalPrice': 50,
        'guestsCount': 1,
        'createdAt': '2026-01-01T09:00:00.000Z',
      });
      expect(booking.status, BookingStatus.completed);
      expect(booking.canCancel, isFalse);
    });
  });

  group('AccessLog.fromJson', () {
    test('parsea log de acceso con visitor', () {
      final log = AccessLog.fromJson({
        'id': 'a1',
        'type': 'VISITOR',
        'status': 'PENDING',
        'visitor': {'id': 'v1', 'firstName': 'Maria', 'lastName': 'Perez'},
        'createdAt': '2026-01-01T09:00:00.000Z',
      });
      expect(log.type, AccessType.visitor);
      expect(log.status, AccessStatus.pending);
      expect(log.displayName, 'Maria Perez');
    });
  });
}