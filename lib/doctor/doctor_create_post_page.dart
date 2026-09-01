part of 'doctor_portal.dart';

class DoctorCreatePostPage extends StatefulWidget {
  const DoctorCreatePostPage({super.key});

  @override
  State<DoctorCreatePostPage> createState() => _DoctorCreatePostPageState();
}

class _DoctorCreatePostPageState extends State<DoctorCreatePostPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  var _coverAsset = '';
  var _attachments = <String>[];

  @override
  void initState() {
    super.initState();
    final draft = DoctorPostStore.instance.draft;
    _title = TextEditingController(text: draft?.title ?? '');
    _content = TextEditingController(text: draft?.content ?? '');
    _coverAsset = draft?.coverAsset ?? '';
    _attachments = [...?draft?.attachmentAssets];
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            _PostBackButton(onPressed: () => Navigator.of(context).pop()),
            const SizedBox.shrink(child: Text('Create Post')),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: DoctorStyles.mint,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  _CoverPicker(asset: _coverAsset, onPressed: _chooseCover),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('doctor-post-title'),
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _composerDecoration('Write a headline....'),
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
                            key: const ValueKey('doctor-post-content'),
                            controller: _content,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(fontSize: 16, height: 1.35),
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
                                  Icons.attach_file_rounded,
                                  color: Color(0xFFB8B8B8),
                                  size: 21,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _attachments.isEmpty
                                      ? 'Attach Images.....'
                                      : '${_attachments.length} images attached',
                                  style: const TextStyle(
                                    color: Color(0xFFB8B8B8),
                                    fontSize: 16,
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
            _PostActionButton(
              key: const ValueKey('publish-doctor-post'),
              label: 'Post',
              large: true,
              onPressed: _publish,
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
    final asset = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => _PostAssetSheet(
        title: 'Choose a cover image',
        assets: const [
          DoctorPostStore.defaultCover,
          'assets/photos/logoandphoto/nways_photo.png',
        ],
      ),
    );
    if (asset != null && mounted) setState(() => _coverAsset = asset);
  }

  Future<void> _chooseAttachments() async {
    final add = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attach images', style: DoctorStyles.title),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Add clinic gallery'),
                subtitle: const Text('Attach three pet photos'),
                onTap: () => Navigator.of(context).pop(true),
              ),
              if (_attachments.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Remove attached images'),
                  onTap: () => Navigator.of(context).pop(false),
                ),
            ],
          ),
        ),
      ),
    );
    if (add == null || !mounted) return;
    setState(() => _attachments = add ? [...DoctorPostStore.gallery] : []);
  }

  DoctorPostDraft _currentDraft() => DoctorPostDraft(
    title: _title.text.trim(),
    content: _content.text.trim(),
    coverAsset: _coverAsset,
    attachmentAssets: List.unmodifiable(_attachments),
  );

  void _saveDraft() {
    DoctorPostStore.instance.saveDraft(_currentDraft());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post saved to drafts.')));
  }

  void _viewDraft() {
    final draft = DoctorPostStore.instance.draft;
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save this post before viewing it.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DoctorPostDetailPage(post: draft.asPost(), title: 'Draft Preview'),
      ),
    );
  }

  void _publish() {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a headline and post content.')),
      );
      return;
    }
    DoctorPostStore.instance.publish(
      title: _title.text.trim(),
      content: _content.text.trim(),
      coverAsset: _coverAsset.isEmpty
          ? DoctorPostStore.defaultCover
          : _coverAsset,
      attachmentAssets: _attachments.isEmpty
          ? DoctorPostStore.gallery
          : _attachments,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post published.')));
    Navigator.of(context).pop();
  }
}

class _PostBackButton extends StatelessWidget {
  const _PostBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      icon: const Icon(Icons.chevron_left_rounded, size: 28),
      label: const Text(
        'Back',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
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
            : _PostImage(asset: asset, cover: true),
      ),
    ),
  );
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.label,
    required this.onPressed,
    this.large = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
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

class _PostAssetSheet extends StatelessWidget {
  const _PostAssetSheet({required this.title, required this.assets});

  final String title;
  final List<String> assets;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DoctorStyles.title),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final asset in assets) ...[
                Expanded(
                  child: GestureDetector(
                    key: ValueKey('doctor-post-asset-$asset'),
                    onTap: () => Navigator.of(context).pop(asset),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 130,
                        child: _PostImage(asset: asset, cover: true),
                      ),
                    ),
                  ),
                ),
                if (asset != assets.last) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    ),
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _PostBackButton(onPressed: () => Navigator.of(context).pop()),
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 14),
              child: Text(widget.title!, style: DoctorStyles.muted),
            )
          else
            const SizedBox(height: 22),
          DoctorPostCard(
            post: widget.post,
            compact: !_expanded,
            onExpand: () => setState(() => _expanded = true),
            onCollapse: () => setState(() => _expanded = false),
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
                child: _PostImage(asset: post.coverAsset, cover: true),
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
            child: _PostImage(asset: post.coverAsset, cover: true),
          ),
        ),
        const SizedBox(height: 16),
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
      child: _PostImage(asset: asset),
    ),
  );
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.asset, this.cover = false});

  final String asset;
  final bool cover;

  @override
  Widget build(BuildContext context) {
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
