import 'package:flutter/material.dart';

import '../data/database_sync.dart';
import 'pet_image.dart';
import 'profile_flows.dart';

/// A compact pet avatar backed by the photo saved in the owner's pet profile.
///
/// Screens that only have a pet name can use this widget without copying photo
/// lookup logic. It also rebuilds when the profile store receives a new photo.
class ProfilePetAvatar extends StatelessWidget {
  const ProfilePetAvatar({
    required this.petName,
    this.species,
    this.radius = 20,
    this.fallbackBackground = const Color(0xFFE6FAF2),
    this.fallbackForeground = const Color(0xFF16855E),
    this.photoKey,
    this.ownerId,
    super.key,
  });

  final String petName;
  final String? species;
  final double radius;
  final Color fallbackBackground;
  final Color fallbackForeground;
  final Key? photoKey;

  /// Database owner used to disambiguate pets with the same name when clinic
  /// staff and doctors can see records belonging to multiple owners.
  final String? ownerId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ProfilePetStore.instance,
    builder: (context, _) {
      final normalizedName = petName.trim().toLowerCase();
      ProfilePet? matchedPet;
      for (final pet in ProfilePetStore.instance.pets) {
        final belongsToOwner =
            ownerId == null || databaseOwnerOf(pet) == ownerId;
        if (pet.name.trim().toLowerCase() == normalizedName && belongsToOwner) {
          matchedPet = pet;
          break;
        }
      }
      final bytes = matchedPet == null
          ? null
          : PetPhoto.decodeDataUri(matchedPet.photoUrl);
      final petSpecies = (matchedPet?.type ?? species ?? '').toLowerCase();
      final fallbackIcon = petSpecies == 'cat'
          ? Icons.cruelty_free_rounded
          : Icons.pets_rounded;

      return Semantics(
        image: bytes != null,
        label: '$petName pet photo',
        child: Container(
          key: photoKey,
          width: radius * 2,
          height: radius * 2,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fallbackBackground,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: bytes == null
              ? Icon(fallbackIcon, color: fallbackForeground, size: radius)
              : Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Icon(
                    fallbackIcon,
                    color: fallbackForeground,
                    size: radius,
                  ),
                ),
        ),
      );
    },
  );
}
