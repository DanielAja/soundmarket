import 'package:flutter_test/flutter_test.dart';
import 'package:soundmarket/features/auth/models/user.dart';

void main() {
  group('User Model Tests', () {
    final testUser = User(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      avatarUrl: 'https://example.com/avatar.jpg',
      isEmailVerified: true,
      createdAt: DateTime(2024, 1, 1),
      lastLoginAt: DateTime(2024, 1, 2),
      metadata: {'key': 'value'},
    );

    test('should create User with all properties', () {
      expect(testUser.id, equals('test-user-id'));
      expect(testUser.email, equals('test@example.com'));
      expect(testUser.displayName, equals('Test User'));
      expect(testUser.avatarUrl, equals('https://example.com/avatar.jpg'));
      expect(testUser.isEmailVerified, isTrue);
      expect(testUser.createdAt, equals(DateTime(2024, 1, 1)));
      expect(testUser.lastLoginAt, equals(DateTime(2024, 1, 2)));
      expect(testUser.metadata, equals({'key': 'value'}));
    });

    test('should create User with optional properties as null', () {
      final minimalUser = User(
        id: 'minimal-id',
        email: 'minimal@example.com',
        displayName: 'Minimal User',
        isEmailVerified: false,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(minimalUser.avatarUrl, isNull);
      expect(minimalUser.lastLoginAt, isNull);
      expect(minimalUser.metadata, isNull);
    });

    test('should create copy with updated properties', () {
      final updatedUser = testUser.copyWith(
        displayName: 'Updated Name',
        isEmailVerified: false,
      );

      expect(updatedUser.id, equals(testUser.id));
      expect(updatedUser.email, equals(testUser.email));
      expect(updatedUser.displayName, equals('Updated Name'));
      expect(updatedUser.isEmailVerified, isFalse);
      expect(updatedUser.avatarUrl, equals(testUser.avatarUrl));
      expect(updatedUser.createdAt, equals(testUser.createdAt));
      expect(updatedUser.lastLoginAt, equals(testUser.lastLoginAt));
      expect(updatedUser.metadata, equals(testUser.metadata));
    });

    test('should serialize to JSON correctly', () {
      final json = testUser.toJson();

      expect(json['id'], equals('test-user-id'));
      expect(json['email'], equals('test@example.com'));
      expect(json['displayName'], equals('Test User'));
      expect(json['avatarUrl'], equals('https://example.com/avatar.jpg'));
      expect(json['isEmailVerified'], isTrue);
      expect(json['createdAt'], equals(DateTime(2024, 1, 1).millisecondsSinceEpoch));
      expect(json['lastLoginAt'], equals(DateTime(2024, 1, 2).millisecondsSinceEpoch));
      expect(json['metadata'], equals({'key': 'value'}));
    });

    test('should deserialize from JSON correctly', () {
      final json = testUser.toJson();
      final deserializedUser = User.fromJson(json);

      expect(deserializedUser.id, equals(testUser.id));
      expect(deserializedUser.email, equals(testUser.email));
      expect(deserializedUser.displayName, equals(testUser.displayName));
      expect(deserializedUser.avatarUrl, equals(testUser.avatarUrl));
      expect(deserializedUser.isEmailVerified, equals(testUser.isEmailVerified));
      expect(deserializedUser.createdAt, equals(testUser.createdAt));
      expect(deserializedUser.lastLoginAt, equals(testUser.lastLoginAt));
      expect(deserializedUser.metadata, equals(testUser.metadata));
    });

    test('should handle null values in JSON deserialization', () {
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'avatarUrl': null,
        'isEmailVerified': false,
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'lastLoginAt': null,
        'metadata': null,
      };

      final user = User.fromJson(json);

      expect(user.avatarUrl, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.metadata, isNull);
    });

    test('should implement equality correctly', () {
      final user1 = User(
        id: 'same-id',
        email: 'user1@example.com',
        displayName: 'User 1',
        isEmailVerified: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final user2 = User(
        id: 'same-id',
        email: 'user2@example.com',
        displayName: 'User 2',
        isEmailVerified: false,
        createdAt: DateTime(2024, 1, 2),
      );

      final user3 = User(
        id: 'different-id',
        email: 'user3@example.com',
        displayName: 'User 3',
        isEmailVerified: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user1, equals(user2)); // Same ID
      expect(user1, isNot(equals(user3))); // Different ID
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1.hashCode, isNot(equals(user3.hashCode)));
    });

    test('should have correct toString format', () {
      final userString = testUser.toString();
      expect(userString, contains('User('));
      expect(userString, contains('id: test-user-id'));
      expect(userString, contains('email: test@example.com'));
      expect(userString, contains('displayName: Test User'));
    });
  });
}