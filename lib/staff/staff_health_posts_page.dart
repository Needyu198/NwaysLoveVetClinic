part of 'staff_portal.dart';

class StaffHealthPostsPage extends StatelessWidget {
  const StaffHealthPostsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Health Posts'),
    body: AnimatedBuilder(
      animation: DoctorPostStore.instance,
      builder: (context, _) {
        final posts = DoctorPostStore.instance.posts;
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 13),
          itemBuilder: (_, index) {
            final post = posts[index];
            return Container(
              decoration: _cardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.coverAsset.isNotEmpty)
                    Image.asset(
                      post.coverAsset,
                      width: double.infinity,
                      height: 125,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          post.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Published by veterinarian • ${_shortDate(post.createdAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
