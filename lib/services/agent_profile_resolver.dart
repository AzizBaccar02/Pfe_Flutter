// lib/services/agent_profile_resolver.dart

import 'package:flutter/foundation.dart';

import '../models/agent_profile_model.dart';
import '../models/offer_interaction_model.dart';
import 'interaction_service.dart';
import 'profile_service.dart';

/// Loads an agent's public profile for a client (photo, city, phone, bio…).
class AgentProfileResolver {
  static Future<AgentProfileModel> resolve({
    required int agentProfileId,
    int? agentUserId,
    int? interactionId,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackPhotoUrl,
  }) async {
    AgentProfileModel? merged;
    var profileId = agentProfileId;

    if (interactionId != null && interactionId > 0) {
      final interaction =
          await InteractionService.getInteractionById(interactionId);
      if (interaction != null) {
        merged = _merge(merged, _fromInteraction(interaction));
        agentUserId ??= interaction.agentUserId;
        if (profileId <= 0 && interaction.agentId > 0) {
          profileId = interaction.agentId;
        }
      }
    }

    final idsToTry = <int>{
      if (agentUserId != null && agentUserId > 0) agentUserId,
      if (profileId > 0) profileId,
    };

    for (final id in idsToTry) {
      merged = _merge(merged, await _fetchFromApi(id));
    }

    merged = _merge(
      merged,
      _fallbackProfile(
        fallbackName: fallbackName,
        fallbackEmail: fallbackEmail,
        fallbackPhotoUrl: fallbackPhotoUrl,
      ),
    );

    debugPrint(
      '[AGENT_PROFILE] resolved agent=$profileId user=$agentUserId '
      'photo=${merged?.photoUrl.isNotEmpty == true} '
      'city=${merged?.city.isNotEmpty == true}',
    );

    return merged ??
        _fallbackProfile(
          fallbackName: fallbackName,
          fallbackEmail: fallbackEmail,
          fallbackPhotoUrl: fallbackPhotoUrl,
        );
  }

  static AgentProfileModel? _fromInteraction(OfferInteractionModel i) {
    return AgentProfileModel(
      firstName: _firstNameFromFull(i.agentName),
      lastName: _lastNameFromFull(i.agentName),
      phone: i.agentPhone ?? '',
      photoUrl: i.agentPhotoUrl ?? '',
      bio: i.agentBio ?? '',
      skills: i.agentSkills ?? '',
      hourlyRate: i.agentHourlyRate ?? 0,
      city: i.agentCity ?? '',
      address: '',
      postalCode: '',
      isProfileCompleted: true,
    );
  }

  static Future<AgentProfileModel?> _fetchFromApi(int id) async {
    return ProfileService.getAgentPublicProfile(id);
  }

  static AgentProfileModel? _merge(
    AgentProfileModel? base,
    AgentProfileModel? patch,
  ) {
    if (patch == null) return base;
    if (base == null) return patch;

    return AgentProfileModel(
      firstName: patch.firstName.isNotEmpty ? patch.firstName : base.firstName,
      lastName: patch.lastName.isNotEmpty ? patch.lastName : base.lastName,
      phone: patch.phone.isNotEmpty ? patch.phone : base.phone,
      photoUrl: patch.photoUrl.isNotEmpty ? patch.photoUrl : base.photoUrl,
      bio: patch.bio.isNotEmpty ? patch.bio : base.bio,
      skills: patch.skills.isNotEmpty ? patch.skills : base.skills,
      hourlyRate: patch.hourlyRate > 0 ? patch.hourlyRate : base.hourlyRate,
      city: patch.city.isNotEmpty ? patch.city : base.city,
      address: patch.address.isNotEmpty ? patch.address : base.address,
      postalCode:
          patch.postalCode.isNotEmpty ? patch.postalCode : base.postalCode,
      isProfileCompleted:
          patch.isProfileCompleted || base.isProfileCompleted,
    );
  }

  static AgentProfileModel _fallbackProfile({
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackPhotoUrl,
  }) {
    final name = fallbackName?.trim() ?? '';
    return AgentProfileModel(
      firstName: _firstNameFromFull(name),
      lastName: _lastNameFromFull(name),
      phone: '',
      photoUrl: fallbackPhotoUrl ?? '',
      bio: '',
      skills: '',
      hourlyRate: 0,
      city: '',
      address: '',
      postalCode: '',
      isProfileCompleted: false,
    );
  }

  static String _firstNameFromFull(String? full) {
    final parts = full?.trim().split(RegExp(r'\s+')) ?? [];
    if (parts.isEmpty) return '';
    return parts.first;
  }

  static String _lastNameFromFull(String? full) {
    final parts = full?.trim().split(RegExp(r'\s+')) ?? [];
    if (parts.length < 2) return '';
    return parts.sublist(1).join(' ');
  }
}
