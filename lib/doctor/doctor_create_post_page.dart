part of 'doctor_portal.dart';

class DoctorCreatePostPage extends StatefulWidget {
  const DoctorCreatePostPage({super.key});

  @override
  State<DoctorCreatePostPage> createState() => _DoctorCreatePostPageState();
}

class _DoctorCreatePostPageState extends State<DoctorCreatePostPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  var _category = 'Pet Health';

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: [
          const Text('Share Clinic Information', style: DoctorStyles.title),
          const SizedBox(height: 6),
          const Text(
            'Create an educational update for pet owners.',
            style: DoctorStyles.muted,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const ['Pet Health', 'Clinic News', 'First Aid', 'Pet Care']
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('doctor-post-title'),
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Post title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('doctor-post-content'),
            controller: _content,
            minLines: 7,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Post content',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('publish-doctor-post'),
            onPressed: _publish,
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Publish Post'),
            style: FilledButton.styleFrom(
              backgroundColor: DoctorStyles.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  void _publish() {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and post content.')),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$_category post published.')));
    Navigator.of(context).pop();
  }
}
