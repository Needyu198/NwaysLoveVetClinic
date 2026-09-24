part of 'doctor_portal.dart';

class DoctorCreatePostPage extends StatefulWidget {
  const DoctorCreatePostPage({this.draft, this.editingPost, super.key});

  final DoctorPostDraft? draft;
  final DoctorPost? editingPost;

  @override
  State<DoctorCreatePostPage> createState() => _DoctorCreatePostPageState();
}

class _DoctorCreatePostPageState extends State<DoctorCreatePostPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  var _coverAsset = '';
  var _attachments = <String>[];
  late final String _draftId;
  late String _category;
  late String _audience;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    final post = widget.editingPost;
    _draftId = draft?.id ?? 'DRAFT-${DateTime.now().microsecondsSinceEpoch}';
    _title = TextEditingController(text: draft?.title ?? post?.title ?? '');
    _content = TextEditingController(
      text: draft?.content ?? post?.content ?? '',
    );
    _coverAsset = draft?.coverAsset ?? post?.coverAsset ?? '';
    _attachments = [...?draft?.attachmentAssets ?? post?.attachmentAssets];
    _category = draft?.category ?? post?.category ?? 'Pet Health';
    _audience = draft?.audience ?? post?.audience ?? 'All Pets';
    _title.addListener(_refreshComposer);
    _content.addListener(_refreshComposer);
  }

  @override
  void dispose() {
    _title.removeListener(_refreshComposer);
    _content.removeListener(_refreshComposer);
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _refreshComposer() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DoctorPageHeader(
              title: widget.editingPost == null ? 'Create Post' : 'Edit Post',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ComposerTip(),
                    const SizedBox(height: 14),
                    _ComposerSection(
                      icon: Icons.image_outlined,
                      title: 'Cover photo',
                      subtitle:
                          'Help pet owners understand your topic quickly.',
                      child: _CoverPicker(
                        asset: _coverAsset,
                        onPressed: _chooseCover,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ComposerSection(
                      icon: Icons.tune_rounded,
                      title: 'Post details',
                      subtitle:
                          'Choose a clear headline and who should see it.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ComposerFieldLabel(
                            label: 'Headline',
                            trailing: '${_title.text.characters.length}/100',
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('doctor-post-title'),
                            controller: _title,
                            maxLength: 100,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _composerDecoration(
                              'Write a clear, helpful headline',
                            ).copyWith(counterText: ''),
                          ),
                          const SizedBox(height: 16),
                          const _ComposerFieldLabel(label: 'Category'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: const ValueKey('doctor-post-category'),
                            isExpanded: true,
                            initialValue: _category,
                            decoration: _composerDecoration('Select category'),
                            items:
                                const [
                                      'Pet Health',
                                      'Nutrition',
                                      'Vaccination',
                                      'Prevention',
                                      'Clinic News',
                                    ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) =>
                                setState(() => _category = value ?? _category),
                          ),
                          const SizedBox(height: 16),
                          const _ComposerFieldLabel(label: 'Audience'),
                          const SizedBox(height: 8),
                          Wrap(
                            key: const ValueKey('doctor-post-audience'),
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final value in const [
                                'All Pets',
                                'Dogs',
                                'Cats',
                              ])
                                ChoiceChip(
                                  label: Text(value),
                                  selected: _audience == value,
                                  onSelected: (_) =>
                                      setState(() => _audience = value),
                                  selectedColor: DoctorStyles.mint,
                                  backgroundColor: DoctorStyles.page,
                                  side: BorderSide(
                                    color: _audience == value
                                        ? DoctorStyles.green
                                        : DoctorStyles.border,
                                  ),
                                  labelStyle: TextStyle(
                                    color: const Color(0xFF24332E),
                                    fontWeight: _audience == value
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                  showCheckmark: true,
                                  checkmarkColor: DoctorStyles.green,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ComposerSection(
                      icon: Icons.edit_note_rounded,
                      title: 'Write your post',
                      subtitle:
                          'Keep advice simple, practical, and easy to scan.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ComposerFieldLabel(
                            label: 'Post content',
                            trailing: '${_content.text.characters.length}/3000',
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('doctor-post-content'),
                            controller: _content,
                            minLines: 9,
                            maxLines: 14,
                            maxLength: 3000,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(fontSize: 16, height: 1.45),
                            decoration:
                                _composerDecoration(
                                  'Share useful advice with pet owners…',
                                ).copyWith(
                                  counterText: '',
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('attach-post-images'),
                            onPressed: _chooseAttachments,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: Text(
                              _attachments.isEmpty
                                  ? 'Add supporting photos'
                                  : 'Add more photos (${_attachments.length})',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DoctorStyles.green,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(
                                color: DoctorStyles.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          if (_attachments.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _AttachmentStrip(
                              attachments: _attachments,
                              onRemove: _removeAttachment,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ComposerSection(
                      icon: Icons.fact_check_outlined,
                      title: 'Before publishing',
                      subtitle:
                          'Save your progress or preview the owner experience.',
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('save-doctor-post-draft'),
                              onPressed: _saveDraft,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save draft'),
                              style: _secondaryActionStyle(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('view-doctor-post-draft'),
                              onPressed: _viewDraft,
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Preview'),
                              style: _secondaryActionStyle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: DoctorStyles.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('schedule-doctor-post'),
                  onPressed: _saving ? null : _schedule,
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DoctorStyles.green,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: DoctorStyles.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey('publish-doctor-post'),
                  onPressed: _saving ? null : _publish,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _saving
                        ? 'Publishing…'
                        : widget.editingPost == null
                        ? 'Publish now'
                        : 'Save changes',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: DoctorStyles.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _composerDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFFB8B8B8),
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: DoctorStyles.page,
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: DoctorStyles.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: DoctorStyles.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: DoctorStyles.green, width: 1.8),
    ),
  );

  ButtonStyle _secondaryActionStyle() => OutlinedButton.styleFrom(
    foregroundColor: DoctorStyles.green,
    minimumSize: const Size.fromHeight(48),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    side: const BorderSide(color: DoctorStyles.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );

  Future<void> _chooseCover() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Cover image', style: DoctorStyles.title),
            ),
            ListTile(
              key: const ValueKey('post-cover-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from gallery'),
              onTap: () => Navigator.of(sheetContext).pop('gallery'),
            ),
            ListTile(
              key: const ValueKey('post-cover-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop('camera'),
            ),
            const Divider(),
            for (final asset in [
              DoctorPostStore.defaultCover,
              ...DoctorPostStore.gallery,
            ])
              ListTile(
                key: ValueKey('doctor-post-asset-$asset'),
                leading: SizedBox.square(
                  dimension: 42,
                  child: DoctorPostImage(asset: asset),
                ),
                title: const Text('Use clinic image'),
                onTap: () => Navigator.of(sheetContext).pop(asset),
              ),
            if (_coverAsset.isNotEmpty)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB3261E),
                ),
                title: const Text(
                  'Remove cover',
                  style: TextStyle(color: Color(0xFFB3261E)),
                ),
                onTap: () => Navigator.of(sheetContext).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'remove') {
      setState(() => _coverAsset = '');
      return;
    }
    if (action.startsWith('assets/')) {
      setState(() => _coverAsset = action);
      return;
    }
    final dataUri = await _pickImageDataUri(
      action == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
    if (dataUri != null && mounted) setState(() => _coverAsset = dataUri);
  }

  Future<void> _chooseAttachments() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload photos'),
              onTap: () => Navigator.pop(sheetContext, 'upload'),
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined),
              title: const Text('Add clinic gallery'),
              onTap: () => Navigator.pop(sheetContext, 'clinic'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'clinic') {
      setState(() {
        _attachments = {..._attachments, ...DoctorPostStore.gallery}.toList();
      });
      return;
    }
    try {
      final picked = await ImagePicker().pickMultiImage(
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (picked.isEmpty || !mounted) return;
      final added = <String>[];
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) continue; // skip >2MB
        added.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }
      if (!mounted) return;
      if (added.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Each photo must be under 2 MB.')),
        );
        return;
      }
      setState(() => _attachments = [..._attachments, ...added]);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the image picker.')),
        );
      }
    }
  }

  /// Picks a single image and returns it as a base64 data URI (or null).
  Future<String?> _pickImageDataUri(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 82,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please choose a photo smaller than 2 MB.'),
            ),
          );
        }
        return null;
      }
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the image picker.')),
        );
      }
      return null;
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments = [..._attachments]..removeAt(index));
  }

  DoctorPostDraft _currentDraft() => DoctorPostDraft(
    id: _draftId,
    title: _title.text.trim(),
    content: _content.text.trim(),
    coverAsset: _coverAsset,
    attachmentAssets: List.unmodifiable(_attachments),
    category: _category,
    audience: _audience,
  );

  Future<void> _saveDraft() async {
    DoctorPostStore.instance.saveDraft(_currentDraft());
    if (DatabaseSync.instance.active) {
      try {
        await DatabaseSync.instance.flushOrThrow();
      } on ClinicApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post saved to drafts.')));
  }

  void _viewDraft() {
    final draft = _currentDraft();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DoctorPostDetailPage(post: draft.asPost(), title: 'Draft Preview'),
      ),
    );
  }

  Future<void> _schedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;
    final scheduledFor = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!scheduledFor.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future date and time.')),
      );
      return;
    }
    await _publish(scheduledFor);
  }

  Future<void> _publish([DateTime? scheduledFor]) async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a headline and post content.')),
      );
      return;
    }
    setState(() => _saving = true);
    final draft = _currentDraft();
    final post = DoctorPostStore.instance.publish(
      title: _title.text.trim(),
      content: _content.text.trim(),
      coverAsset: _coverAsset.isEmpty
          ? DoctorPostStore.defaultCover
          : _coverAsset,
      attachmentAssets: _attachments,
      category: _category,
      audience: _audience,
      draftId: _draftId,
      replacing: widget.editingPost,
      scheduledFor: scheduledFor,
    );
    if (DatabaseSync.instance.active) {
      try {
        await DatabaseSync.instance.flushOrThrow();
      } on ClinicApiException catch (error) {
        if (widget.editingPost == null) {
          DoctorPostStore.instance.deletePost(post);
          DoctorPostStore.instance.saveDraft(draft);
        } else {
          DoctorPostStore.instance._replace(post, widget.editingPost!);
        }
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not publish: ${error.message}')),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheduledFor == null ? 'Post published.' : 'Post scheduled.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }
}

class DoctorPostsManagerPage extends StatelessWidget {
  const DoctorPostsManagerPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DoctorStyles.page,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _DoctorPageHeader(title: 'My Posts'),
          Expanded(
            child: AnimatedBuilder(
              animation: DoctorPostStore.instance,
              builder: (context, _) {
                final store = DoctorPostStore.instance;
                final accountId = ClinicApi.instance.accountId;
                final posts = store.allPosts.where(
                  (post) =>
                      accountId.isEmpty ||
                      post.authorId.isEmpty ||
                      post.authorId == accountId,
                );
                final published = posts
                    .where((post) => post.status == 'published')
                    .toList();
                final scheduled = posts
                    .where((post) => post.status == 'scheduled')
                    .toList();
                final archived = posts
                    .where((post) => post.status == 'archived')
                    .toList();
                final drafts = store.drafts;
                return ListView(
                  key: const ValueKey('doctor-posts-manager'),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                  children: [
                    _PostsOverview(
                      published: published.length,
                      scheduled: scheduled.length,
                      drafts: drafts.length,
                      archived: archived.length,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      key: const ValueKey('doctor-new-post'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorCreatePostPage(),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create New Post'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DoctorStyles.mint,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PostManagerSection(
                      title: 'Drafts',
                      empty: 'No saved drafts.',
                      icon: Icons.edit_note_rounded,
                      accent: const Color(0xFF8A6D00),
                      children: [
                        for (final draft in drafts)
                          _DraftManagerCard(
                            draft: draft,
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorCreatePostPage(draft: draft),
                              ),
                            ),
                            onDelete: () => _deleteDraft(context, draft),
                          ),
                      ],
                    ),
                    _PostManagerSection(
                      title: 'Scheduled',
                      empty: 'No scheduled posts.',
                      icon: Icons.schedule_rounded,
                      accent: const Color(0xFF1C6BD8),
                      children: [
                        for (final post in scheduled)
                          _PublishedManagerCard(
                            post: post,
                            onPreview: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorPostDetailPage(post: post),
                              ),
                            ),
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorCreatePostPage(editingPost: post),
                              ),
                            ),
                            onArchive: () => _archivePost(context, post),
                            onDelete: () => _deletePost(context, post),
                          ),
                      ],
                    ),
                    _PostManagerSection(
                      title: 'Published',
                      empty: 'No published posts.',
                      icon: Icons.public_rounded,
                      accent: DoctorStyles.green,
                      children: [
                        for (final post in published)
                          _PublishedManagerCard(
                            post: post,
                            onPreview: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorPostDetailPage(post: post),
                              ),
                            ),
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorCreatePostPage(editingPost: post),
                              ),
                            ),
                            onArchive: () => _archivePost(context, post),
                            onDelete: () => _deletePost(context, post),
                          ),
                      ],
                    ),
                    _PostManagerSection(
                      title: 'Archived',
                      empty: 'No archived posts.',
                      icon: Icons.inventory_2_outlined,
                      accent: const Color(0xFF6B7280),
                      children: [
                        for (final post in archived)
                          _PublishedManagerCard(
                            post: post,
                            onPreview: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorPostDetailPage(post: post),
                              ),
                            ),
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorCreatePostPage(editingPost: post),
                              ),
                            ),
                            onArchive: () => _restorePost(context, post),
                            onDelete: () => _deletePost(context, post),
                            archived: true,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _archivePost(BuildContext context, DoctorPost post) async {
    DoctorPostStore.instance.archive(post);
    try {
      await _finishChange(context, 'Post archived.');
    } on ClinicApiException catch (error) {
      DoctorPostStore.instance.restorePostSnapshot(post);
      if (context.mounted) _showSyncError(context, error);
    }
  }

  Future<void> _restorePost(BuildContext context, DoctorPost post) async {
    DoctorPostStore.instance.restore(post);
    try {
      await _finishChange(context, 'Post published again.');
    } on ClinicApiException catch (error) {
      DoctorPostStore.instance.restorePostSnapshot(post);
      if (context.mounted) _showSyncError(context, error);
    }
  }

  Future<void> _deletePost(BuildContext context, DoctorPost post) async {
    if (!await _confirmDelete(context, post.title)) return;
    if (!context.mounted) return;
    DoctorPostStore.instance.deletePost(post);
    try {
      await _finishChange(context, 'Post deleted.');
    } on ClinicApiException catch (error) {
      DoctorPostStore.instance.restorePostSnapshot(post);
      if (context.mounted) _showSyncError(context, error);
    }
  }

  Future<void> _deleteDraft(BuildContext context, DoctorPostDraft draft) async {
    if (!await _confirmDelete(
      context,
      draft.title.isEmpty ? 'Draft' : draft.title,
    )) {
      return;
    }
    if (!context.mounted) return;
    DoctorPostStore.instance.deleteDraft(draft.id);
    try {
      await _finishChange(context, 'Draft deleted.');
    } on ClinicApiException catch (error) {
      DoctorPostStore.instance.saveDraft(draft);
      if (context.mounted) _showSyncError(context, error);
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete permanently?'),
          content: Text('“$title” will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _finishChange(BuildContext context, String message) async {
    if (DatabaseSync.instance.active) {
      await DatabaseSync.instance.flushOrThrow();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showSyncError(BuildContext context, ClinicApiException error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Change was not saved: ${error.message}')),
    );
  }
}

class _PostsOverview extends StatelessWidget {
  const _PostsOverview({
    required this.published,
    required this.scheduled,
    required this.drafts,
    required this.archived,
  });

  final int published;
  final int scheduled;
  final int drafts;
  final int archived;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: DoctorStyles.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D1F4B3C),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        _OverviewStat(
          label: 'Published',
          value: published,
          color: DoctorStyles.green,
        ),
        const _OverviewDivider(),
        _OverviewStat(
          label: 'Scheduled',
          value: scheduled,
          color: const Color(0xFF1C6BD8),
        ),
        const _OverviewDivider(),
        _OverviewStat(
          label: 'Drafts',
          value: drafts,
          color: const Color(0xFF8A6D00),
        ),
        const _OverviewDivider(),
        _OverviewStat(
          label: 'Archived',
          value: archived,
          color: const Color(0xFF6B7280),
        ),
      ],
    ),
  );
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5A6864),
          ),
        ),
      ],
    ),
  );
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: DoctorStyles.border);
}

class _PostManagerSection extends StatelessWidget {
  const _PostManagerSection({
    required this.title,
    required this.empty,
    required this.icon,
    required this.accent,
    required this.children,
  });

  final String title;
  final String empty;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 8),
            Text(title, style: DoctorStyles.title),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${children.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DoctorStyles.border),
            ),
            child: Text(empty, style: DoctorStyles.muted),
          )
        else
          ...children,
      ],
    ),
  );
}

class _DraftManagerCard extends StatelessWidget {
  const _DraftManagerCard({
    required this.draft,
    required this.onEdit,
    required this.onDelete,
  });

  final DoctorPostDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: DoctorStyles.border),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('doctor-draft-${draft.id}'),
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF8A6D00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.title.isEmpty ? 'Untitled draft' : draft.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DoctorStyles.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${draft.category} • Updated ${_shortDate(draft.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DoctorStyles.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _StatusPill(label: 'Draft', color: const Color(0xFF8A6D00)),
              IconButton(
                tooltip: 'Delete draft',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF9AA6A1),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    ),
  );
}

class _PublishedManagerCard extends StatelessWidget {
  const _PublishedManagerCard({
    required this.post,
    required this.onPreview,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
    this.archived = false,
  });

  final DoctorPost post;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final bool archived;

  ({String label, Color color}) get _statusBadge => switch (post.status) {
    'scheduled' => (label: 'Scheduled', color: const Color(0xFF1C6BD8)),
    'archived' => (label: 'Archived', color: const Color(0xFF6B7280)),
    _ => (label: 'Published', color: DoctorStyles.green),
  };

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DoctorStyles.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('manage-doctor-post-${post.id}'),
          onTap: onPreview,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox.square(
                    dimension: 58,
                    child: DoctorPostImage(asset: post.coverAsset, cover: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DoctorStyles.cardTitle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusPill(label: badge.label, color: badge.color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.category} • ${post.audience}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DoctorStyles.muted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.status == 'scheduled' && post.scheduledFor != null
                            ? 'Scheduled for ${_shortDate(post.scheduledFor!)}'
                            : 'Updated ${_shortDate(post.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DoctorStyles.small,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: PopupMenuButton<String>(
                    tooltip: 'Post actions',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF6B7772),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'preview':
                          onPreview();
                        case 'edit':
                          onEdit();
                        case 'archive':
                          onArchive();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'preview',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.visibility_outlined),
                          title: Text('Preview'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            archived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                          ),
                          title: Text(archived ? 'Publish again' : 'Archive'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFB3261E),
                          ),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFB3261E)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerTip extends StatelessWidget {
  const _ComposerTip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline_rounded, color: DoctorStyles.green),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Use a clear title, short paragraphs, and practical advice pet owners can follow.',
            style: TextStyle(
              color: Color(0xFF40504A),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ComposerSection extends StatelessWidget {
  const _ComposerSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: DoctorStyles.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D1F4B3C),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DoctorStyles.mint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: DoctorStyles.green, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1F2C28),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF71807B),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _ComposerFieldLabel extends StatelessWidget {
  const _ComposerFieldLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33413C),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(
            color: Color(0xFF87938F),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
    ],
  );
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.asset, required this.onPressed});

  final String asset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: DoctorStyles.page,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: const ValueKey('doctor-post-cover'),
      onTap: onPressed,
      child: Container(
        height: 182,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DoctorStyles.border),
        ),
        child: asset.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: DoctorStyles.mint,
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: DoctorStyles.green,
                        size: 27,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Add cover photo',
                      style: TextStyle(
                        color: Color(0xFF33413C),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Recommended 16:9 • JPG or PNG',
                      style: TextStyle(color: Color(0xFF7A8782), fontSize: 12),
                    ),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  DoctorPostImage(asset: asset, cover: true),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD9000000),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 15,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Change cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _AttachmentStrip extends StatelessWidget {
  const _AttachmentStrip({required this.attachments, required this.onRemove});

  final List<String> attachments;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 92,
                child: DoctorPostImage(asset: attachments[index]),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                key: ValueKey('remove-post-attachment-$index'),
                onTap: () => onRemove(index),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorPostDetailPage extends StatefulWidget {
  const DoctorPostDetailPage({required this.post, this.title, super.key});

  final DoctorPost post;
  final String? title;

  @override
  State<DoctorPostDetailPage> createState() => _DoctorPostDetailPageState();
}

class _DoctorPostDetailPageState extends State<DoctorPostDetailPage> {
  late var _expanded = widget.title != null;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          _DoctorPageHeader(title: widget.title ?? 'Info Sharing'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              children: [
                DoctorPostCard(
                  post: widget.post,
                  compact: !_expanded,
                  onExpand: () => setState(() => _expanded = true),
                  onCollapse: () => setState(() => _expanded = false),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardFeedCard extends StatelessWidget {
  const _DashboardFeedCard({required this.post});

  final DoctorPost post;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    elevation: 4,
    shadowColor: const Color(0x33000000),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('open-doctor-post-${post.id}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DoctorPostDetailPage(post: post),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 178,
                width: double.infinity,
                child: DoctorPostImage(asset: post.coverAsset, cover: true),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _FeedTag(label: post.category),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DoctorStyles.ink,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: DoctorStyles.softMint,
                      child: widgetForDoctorPostAuthor(post),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: DoctorStyles.ink,
                            ),
                          ),
                          Text(
                            '${post.audience} • ${_shortDate(post.updatedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DoctorStyles.small,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: DoctorStyles.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeedTag extends StatelessWidget {
  const _FeedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: DoctorStyles.green,
      ),
    ),
  );
}

class DoctorPostCard extends StatelessWidget {
  const DoctorPostCard({
    required this.post,
    required this.compact,
    this.onExpand,
    this.onCollapse,
    super.key,
  });

  final DoctorPost post;
  final bool compact;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('doctor-post-${post.id}'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(28),
      boxShadow: compact
          ? const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ]
          : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: DoctorPostImage(asset: post.coverAsset, cover: true),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: widgetForDoctorPostAuthor(post),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    [
                      if (post.authorSpecialty.isNotEmpty) post.authorSpecialty,
                      post.category,
                      post.audience,
                    ].join(' • '),
                    style: DoctorStyles.small,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          post.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 25,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        if (compact)
          InkWell(
            key: ValueKey('expand-doctor-post-${post.id}'),
            onTap: onExpand,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${_compactPostText(post.content)}... '),
                  const TextSpan(
                    text: 'See More',
                    style: TextStyle(color: Color(0xFF777F7D)),
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                height: 1.35,
              ),
            ),
          )
        else
          InkWell(
            key: ValueKey('collapse-doctor-post-${post.id}'),
            onTap: onCollapse,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: post.content),
                  const TextSpan(
                    text: '  See Less',
                    style: TextStyle(color: Color(0xFF777F7D)),
                  ),
                ],
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ),
        if (post.attachmentAssets.isNotEmpty) ...[
          const SizedBox(height: 14),
          if (compact)
            _CompactPostGallery(assets: post.attachmentAssets)
          else
            _ExpandedPostGallery(assets: post.attachmentAssets),
        ],
      ],
    ),
  );
}

Widget widgetForDoctorPostAuthor(DoctorPost post) {
  final source = post.authorPhoto;
  if (source != null && source.isNotEmpty) {
    if (source.startsWith('data:')) {
      final bytes = _decodePostDataUri(source);
      if (bytes != null) {
        return ClipOval(child: Image.memory(bytes, fit: BoxFit.cover));
      }
    }
    if (source.startsWith('assets/')) {
      return ClipOval(child: Image.asset(source, fit: BoxFit.cover));
    }
  }
  return Text(
    post.authorName.trim().isEmpty
        ? 'V'
        : post.authorName.trim().substring(0, 1).toUpperCase(),
    style: const TextStyle(fontWeight: FontWeight.w900),
  );
}

class _CompactPostGallery extends StatelessWidget {
  const _CompactPostGallery({required this.assets});

  final List<String> assets;

  @override
  Widget build(BuildContext context) {
    final visible = assets.take(3).toList();
    return SizedBox(
      height: 218,
      child: Row(
        children: [
          Expanded(flex: 2, child: _GalleryTile(asset: visible.first)),
          if (visible.length > 1) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _GalleryTile(asset: visible[1])),
                  if (visible.length > 2) ...[
                    const SizedBox(height: 14),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _GalleryTile(asset: visible[2]),
                          if (assets.length >= 3)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x66000000),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Text(
                                  '+${assets.length - 2}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandedPostGallery extends StatelessWidget {
  const _ExpandedPostGallery({required this.assets});

  final List<String> assets;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < assets.length; index++) ...[
        _GalleryTile(asset: assets[index], height: 245),
        if (index != assets.length - 1) const SizedBox(height: 16),
      ],
    ],
  );
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.asset, this.height});

  final String asset;
  final double? height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: DoctorPostImage(asset: asset),
    ),
  );
}

/// Decodes a base64 data URI (`data:image/...;base64,...`) to bytes, or null.
Uint8List? _decodePostDataUri(String value) {
  if (!value.startsWith('data:')) return null;
  final comma = value.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(value.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

class DoctorPostImage extends StatelessWidget {
  const DoctorPostImage({required this.asset, this.cover = false, super.key});

  final String asset;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    // Uploaded photos are stored inline as base64 data URIs.
    final bytes = _decodePostDataUri(asset);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        alignment: cover ? Alignment.center : Alignment.topCenter,
        gaplessPlayback: true,
      );
    }
    if (asset == DoctorPostStore.defaultCover) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF068FD2), Color(0xFFB8EEFF)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              right: 12,
              top: 8,
              child: Icon(Icons.cloud, size: 82, color: Color(0xDDFFFFFF)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                asset,
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),
          ],
        ),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: cover ? Alignment.center : Alignment.topCenter,
    );
  }
}

String _compactPostText(String value) {
  final normalized = value.replaceAll('\n', ' ').trim();
  if (normalized.length <= 86) return normalized;
  return normalized.substring(0, 86).trimRight();
}
