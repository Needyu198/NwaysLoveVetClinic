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
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: DoctorStyles.mint,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          children: [
                            _CoverPicker(
                              asset: _coverAsset,
                              onPressed: _chooseCover,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              key: const ValueKey('doctor-post-title'),
                              controller: _title,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: _composerDecoration(
                                'Write a headline....',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: const ValueKey('doctor-post-category'),
                                    isExpanded: true,
                                    initialValue: _category,
                                    decoration: _composerDecoration('Category'),
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
                                                child: Text(
                                                  value,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) => setState(
                                      () => _category = value ?? _category,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: const ValueKey('doctor-post-audience'),
                                    isExpanded: true,
                                    initialValue: _audience,
                                    decoration: _composerDecoration('Audience'),
                                    items: const ['All Pets', 'Dogs', 'Cats']
                                        .map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(
                                              value,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                      () => _audience = value ?? _audience,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 448,
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      key: const ValueKey(
                                        'doctor-post-content',
                                      ),
                                      controller: _content,
                                      expands: true,
                                      maxLines: null,
                                      minLines: null,
                                      textAlignVertical: TextAlignVertical.top,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.35,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Write a post....',
                                        hintStyle: TextStyle(
                                          color: Color(0xFFB8B8B8),
                                          fontWeight: FontWeight.w700,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    key: const ValueKey('attach-post-images'),
                                    onTap: _chooseAttachments,
                                    borderRadius: BorderRadius.circular(18),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: Color(0xFF525C59),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _attachments.isEmpty
                                                  ? 'Add photos.....'
                                                  : '${_attachments.length} photo(s) added • tap to add more',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF777F7D),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _PostActionButton(
                              key: const ValueKey('save-doctor-post-draft'),
                              label: 'Save to Draft',
                              onPressed: _saveDraft,
                            ),
                          ),
                          const SizedBox(width: 34),
                          Expanded(
                            child: _PostActionButton(
                              key: const ValueKey('view-doctor-post-draft'),
                              label: 'View Draft',
                              onPressed: _viewDraft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _PostActionButton(
                              key: const ValueKey('publish-doctor-post'),
                              label: _saving
                                  ? 'Publishing…'
                                  : widget.editingPost == null
                                  ? 'Post Now'
                                  : 'Save Post',
                              large: true,
                              onPressed: _saving ? null : _publish,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PostActionButton(
                              key: const ValueKey('schedule-doctor-post'),
                              label: 'Schedule',
                              large: true,
                              onPressed: _saving ? null : _schedule,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    ),
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
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PostManagerSection(
                      title: 'Drafts',
                      empty: 'No saved drafts.',
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

class _PostManagerSection extends StatelessWidget {
  const _PostManagerSection({
    required this.title,
    required this.empty,
    required this.children,
  });

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title (${children.length})', style: DoctorStyles.title),
        const SizedBox(height: 10),
        if (children.isEmpty)
          Text(empty, style: DoctorStyles.muted)
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
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      key: ValueKey('doctor-draft-${draft.id}'),
      leading: const Icon(Icons.edit_note_rounded),
      title: Text(draft.title.isEmpty ? 'Untitled draft' : draft.title),
      subtitle: Text(
        '${draft.category} • Updated ${_shortDate(draft.updatedAt)}',
      ),
      onTap: onEdit,
      trailing: IconButton(
        tooltip: 'Delete draft',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
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

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      key: ValueKey('manage-doctor-post-${post.id}'),
      leading: SizedBox.square(
        dimension: 48,
        child: DoctorPostImage(asset: post.coverAsset, cover: true),
      ),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${post.category} • ${_shortDate(post.updatedAt)}'),
      onTap: onPreview,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'archive':
              onArchive();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(
            value: 'archive',
            child: Text(archived ? 'Publish again' : 'Archive'),
          ),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    ),
  );
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.asset, required this.onPressed});

  final String asset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFB8C8C4),
    borderRadius: BorderRadius.circular(27),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: const ValueKey('doctor-post-cover'),
      onTap: onPressed,
      child: SizedBox(
        height: 202,
        child: asset.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file_outlined, color: Color(0xFF525C59)),
                    SizedBox(height: 9),
                    Text(
                      'Upload a cover image',
                      style: TextStyle(
                        color: Color(0xFF777F7D),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : DoctorPostImage(asset: asset, cover: true),
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

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.label,
    required this.onPressed,
    this.large = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: DoctorStyles.mint,
      foregroundColor: Colors.black,
      elevation: 0,
      minimumSize: Size.fromHeight(large ? 48 : 46),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: const StadiumBorder(),
      textStyle: TextStyle(
        fontSize: large ? 25 : 18,
        fontWeight: large ? FontWeight.w500 : FontWeight.w600,
      ),
    ),
    child: FittedBox(child: Text(label)),
  );
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
    color: DoctorStyles.mint,
    borderRadius: BorderRadius.circular(28),
    elevation: 5,
    shadowColor: const Color(0x55000000),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('open-doctor-post-${post.id}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DoctorPostDetailPage(post: post),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 215,
                width: double.infinity,
                child: DoctorPostImage(asset: post.coverAsset, cover: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 28),
              child: Text(
                post.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
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
