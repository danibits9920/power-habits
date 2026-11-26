import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_habits/core/updater.dart';
import 'package:power_habits/data/backup.dart';
import 'package:power_habits/data/db.dart';

void main() {
  group('Updater semver & release parsing', () {
    test('parseSemver strips prefix, build metadata and prerelease suffix', () {
      expect(parseSemver('v1.2.3+4'), [1, 2, 3]);
      expect(parseSemver('V0.10.2-beta.1'), [0, 10, 2]);
      expect(parseSemver(' 2.4 '), [2, 4, 0]);
      expect(parseSemver('0.1.0'), [0, 1, 0]);
    });

    test('isNewerVersion compares semantic versions accurately', () {
      expect(isNewerVersion('0.1.0', '0.1.1'), isTrue);
      expect(isNewerVersion('0.1.0', '0.2.0'), isTrue);
      expect(isNewerVersion('0.1.0', '1.0.0'), isTrue);
      expect(isNewerVersion('0.1.0', 'v0.1.0+1'), isFalse);
      expect(isNewerVersion('1.2.0', '1.1.9'), isFalse);
      expect(isNewerVersion('1.2.3', '0.9.9'), isFalse);
    });

    test('parseReleaseNotes cleans bullet prefixes and empty lines', () {
      const raw = '''
      - Primera mejora
      * Segunda mejora
      3. Tercera mejora

      • Cuarta mejora
      ''';
      expect(parseReleaseNotes(raw), [
        'Primera mejora',
        'Segunda mejora',
        'Tercera mejora',
        'Cuarta mejora',
      ]);
    });

    test('AppRelease.fromGithubJson prefers arm64 APK asset', () {
      final json = <String, dynamic>{
        'tag_name': 'v0.2.0',
        'name': 'Power Habits v0.2.0',
        'body': '- Mejoras de rendimiento\n- Nuevo widget',
        'assets': [
          {
            'name': 'power-habits-v0.2.0-universal.apk',
            'browser_download_url':
                'https://example.com/power-habits-v0.2.0-universal.apk',
            'size': 28000000,
          },
          {
            'name': 'power-habits-v0.2.0-arm64.apk',
            'browser_download_url':
                'https://example.com/power-habits-v0.2.0-arm64.apk',
            'size': 19500000,
          },
          {
            'name': 'checksums.txt',
            'browser_download_url': 'https://example.com/checksums.txt',
            'size': 512,
          },
        ],
      };

      final release = AppRelease.fromGithubJson(json);
      expect(release.version, '0.2.0');
      expect(release.tagName, 'v0.2.0');
      expect(release.title, 'Power Habits v0.2.0');
      expect(release.apkName, 'power-habits-v0.2.0-arm64.apk');
      expect(
        release.apkUrl,
        'https://example.com/power-habits-v0.2.0-arm64.apk',
      );
      expect(release.sizeBytes, 19500000);
    });

    test('AppRelease.fromGithubJson throws when tag or APK is missing', () {
      expect(
        () => AppRelease.fromGithubJson({'tag_name': '', 'assets': []}),
        throwsFormatException,
      );
      expect(
        () => AppRelease.fromGithubJson({
          'tag_name': 'v0.2.0',
          'assets': [
            {
              'name': 'README.txt',
              'browser_download_url': 'https://example.com/README.txt',
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('JSON Backup export & import roundtrip', () {
    late AppDb sourceDb;
    late AppDb targetDb;

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    setUp(() {
      sourceDb = AppDb.forTesting(NativeDatabase.memory());
      targetDb = AppDb.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await sourceDb.close();
      await targetDb.close();
    });

    test(
      'exports all 6 tables and restores exact records into a clean DB',
      () async {
        const ts = '2026-11-26T12:00:00.000Z';

        await sourceDb.into(sourceDb.routines).insert(
              RoutinesCompanion.insert(
                id: 'r-1',
                title: 'Caminar 30 minutos',
                itemType: const Value('routine'),
                context: const Value('personal'),
                timeSlot: const Value('morning'),
                frequencyType: const Value('alternate'),
                weekdaysMask: const Value('1,3,5'),
                anchorDate: '2026-11-20',
                reminderTimes: const Value('07:00,18:30'),
                allowQuickNote: const Value(true),
                sortOrder: const Value(2),
                createdAt: ts,
                updatedAt: ts,
              ),
            );

        await sourceDb.into(sourceDb.routineLogs).insert(
              RoutineLogsCompanion.insert(
                id: 'l-1',
                routineId: 'r-1',
                logDate: '2026-11-26',
                completed: const Value(true),
                note: const Value('Excelente ritmo matutino'),
                completedAt: const Value(ts),
                createdAt: ts,
                updatedAt: ts,
              ),
            );

        await sourceDb.into(sourceDb.goals).insert(
              GoalsCompanion.insert(
                id: 'g-1',
                title: 'Curso de Flutter avanzado',
                context: const Value('work'),
                unitLabel: const Value('clases'),
                currentValue: const Value(15),
                targetValue: const Value(30),
                milestonesUnlocked: const Value('25,50'),
                createdAt: ts,
                updatedAt: ts,
              ),
            );

        await sourceDb.into(sourceDb.goalSteps).insert(
              GoalStepsCompanion.insert(
                id: 'gs-1',
                goalId: 'g-1',
                stepIndex: 1,
                title: 'Arquitectura local-first con Drift',
                completed: const Value(true),
                note: const Value('Completado con pruebas'),
                completedAt: const Value(ts),
                createdAt: ts,
                updatedAt: ts,
              ),
            );

        await sourceDb.into(sourceDb.achievements).insert(
              AchievementsCompanion.insert(
                id: 'a-1',
                kind: const Value('auto'),
                title: '50 % completado — Curso de Flutter avanzado',
                detail: const Value('Hito automático (15/30 clases)'),
                context: const Value('work'),
                sourceKey: const Value('goal:g-1:50'),
                achievedDate: '2026-11-26',
                createdAt: ts,
                updatedAt: ts,
              ),
            );

        await sourceDb.into(sourceDb.appSettings).insert(
              AppSettingsCompanion.insert(
                key: 'theme_mode',
                value: 'dark',
                updatedAt: ts,
              ),
            );

        final exported = await exportBackupJson(sourceDb);
        final decoded = jsonDecode(exported) as Map<String, dynamic>;
        expect(decoded['app'], 'power_habits');
        expect(decoded['schemaVersion'], 1);

        final result = await importBackupJson(targetDb, exported);
        expect(result.routines, 1);
        expect(result.routineLogs, 1);
        expect(result.goals, 1);
        expect(result.goalSteps, 1);
        expect(result.achievements, 1);
        expect(result.appSettings, 1);
        expect(result.totalRecords, 6);

        final routines = await targetDb.select(targetDb.routines).get();
        expect(routines.single.id, 'r-1');
        expect(routines.single.title, 'Caminar 30 minutos');
        expect(routines.single.reminderTimes, '07:00,18:30');
        expect(routines.single.frequencyType, 'alternate');

        final logs = await targetDb.select(targetDb.routineLogs).get();
        expect(logs.single.completed, isTrue);
        expect(logs.single.note, 'Excelente ritmo matutino');

        final goals = await targetDb.select(targetDb.goals).get();
        expect(goals.single.currentValue, 15);
        expect(goals.single.targetValue, 30);
        expect(goals.single.milestonesUnlocked, '25,50');

        final steps = await targetDb.select(targetDb.goalSteps).get();
        expect(steps.single.title, 'Arquitectura local-first con Drift');
        expect(steps.single.completed, isTrue);

        final achievements = await targetDb.select(targetDb.achievements).get();
        expect(achievements.single.sourceKey, 'goal:g-1:50');
        expect(achievements.single.kind, 'auto');

        final settings = await targetDb.select(targetDb.appSettings).get();
        expect(settings.single.key, 'theme_mode');
        expect(settings.single.value, 'dark');

        // Re-import is idempotent (upsert without duplicate key errors).
        final secondImport = await importBackupJson(targetDb, exported);
        expect(secondImport.totalRecords, 6);
        expect((await targetDb.select(targetDb.routines).get()).length, 1);
      },
    );

    test('importBackupJson rejects malformed backup payloads', () async {
      await expectLater(
        () => importBackupJson(targetDb, '{"not_tables": []}'),
        throwsFormatException,
      );
    });
  });
}
