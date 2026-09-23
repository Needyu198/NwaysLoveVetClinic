import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/doctor/doctor_portal.dart';
import 'package:senior_project/pet_owner/pet_owner_home_page.dart';
import 'package:senior_project/staff/staff_portal.dart';

const _pixel =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

void main() {
  tearDown(DoctorPostStore.instance.reset);

  testWidgets(
    'create post composer has guided sections and reachable actions',
    (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: DoctorCreatePostPage()));

      expect(find.text('Cover photo'), findsOneWidget);
      expect(find.text('Post details'), findsOneWidget);
      expect(find.text('Write your post'), findsOneWidget);
      expect(find.text('0/100'), findsOneWidget);
      expect(find.byKey(const ValueKey('publish-doctor-post')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('schedule-doctor-post')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('doctor-post-title')),
        'Healthy pets',
      );
      await tester.pump();
      expect(find.text('12/100'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Cats'));
      await tester.pump();
      final catsChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Cats'),
      );
      expect(catsChip.selected, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'doctor post lifecycle supports multiple drafts and archive restore',
    () {
      final store = DoctorPostStore.instance;
      store.reset();

      final firstDraft = DoctorPostDraft(
        id: 'draft-one',
        title: 'Nutrition draft',
        content: 'Nutrition guidance',
        coverAsset: _pixel,
        attachmentAssets: const [],
        category: 'Nutrition',
        audience: 'Dogs',
      );
      final secondDraft = DoctorPostDraft(
        id: 'draft-two',
        title: 'Vaccine draft',
        content: 'Vaccination guidance',
        coverAsset: _pixel,
        attachmentAssets: const [],
        category: 'Vaccination',
        audience: 'Cats',
      );
      store
        ..saveDraft(firstDraft)
        ..saveDraft(secondDraft);

      expect(store.drafts, hasLength(2));
      final post = store.publish(
        title: firstDraft.title,
        content: firstDraft.content,
        coverAsset: firstDraft.coverAsset,
        attachmentAssets: firstDraft.attachmentAssets,
        category: firstDraft.category,
        audience: firstDraft.audience,
        draftId: firstDraft.id,
      );

      expect(store.drafts.single.id, secondDraft.id);
      expect(store.posts.first, same(post));
      expect(post.category, 'Nutrition');
      expect(post.audience, 'Dogs');

      store.archive(post);
      expect(store.posts.any((item) => item.id == post.id), isFalse);
      expect(
        store.allPosts.singleWhere((item) => item.id == post.id).status,
        'archived',
      );

      final archived = store.allPosts.singleWhere((item) => item.id == post.id);
      store.restore(archived);
      expect(store.posts.any((item) => item.id == post.id), isTrue);
    },
  );

  testWidgets('manager and cross-role feeds show published post and image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DoctorPostStore.instance;
    store.reset();
    store.saveDraft(
      DoctorPostDraft(
        id: 'manager-draft',
        title: 'Saved draft',
        content: 'Draft content',
        coverAsset: _pixel,
        attachmentAssets: const [],
      ),
    );
    store.publish(
      title: 'Dental health matters',
      content: 'Brush regularly and schedule dental checks.',
      coverAsset: _pixel,
      attachmentAssets: const [_pixel],
      category: 'Prevention',
      audience: 'All Pets',
    );

    await tester.pumpWidget(const MaterialApp(home: DoctorPostsManagerPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-posts-manager')), findsOneWidget);
    expect(find.text('Drafts (1)'), findsOneWidget);
    expect(find.text('Published (2)'), findsOneWidget);
    expect(find.text('Saved draft'), findsOneWidget);
    expect(find.text('Dental health matters'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: StaffHealthPostsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Dental health matters'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.pumpWidget(const MaterialApp(home: OwnerInfoSharingPage()));
    await tester.pumpAndSettle();
    expect(find.text('Dental health matters'), findsOneWidget);
  });

  test('old post records remain backward compatible', () {
    final post = DoctorPost.fromDb({
      'id': 'legacy-post',
      'title': 'Legacy',
      'content': 'Older saved content',
      'coverAsset': DoctorPostStore.defaultCover,
      'attachmentAssets': <String>[],
      'createdAt': '2026-01-01T00:00:00.000',
    });

    expect(post.authorName, 'Clinic Veterinarian');
    expect(post.category, 'Pet Health');
    expect(post.status, 'published');
    expect(post.isPublished, isTrue);
  });
}
