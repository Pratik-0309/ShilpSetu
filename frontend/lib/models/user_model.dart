/// Represents a ShilpSetu user profile stored in Firestore "users" collection.
///
/// This is separate from Firebase Auth — Auth handles credentials,
/// Firestore "users" handles display info and role.
class UserModel {
  final String uid;
  final String name;
  final String email;

  /// Either "artisan" or "buyer".
  final String role;

  final String phone;
  final String languagePreference;
  final String artisanCluster;
  final String region;

  // New Profile Completion Fields
  final String dateOfBirth;
  final String gender;
  final String maritalStatus;
  final int    experienceYears;
  final String profilePhotoUrl;
  final String coverPhotoUrl;
  final String artisanStory;
  final bool   isProfileCompleted;

  // Buyer & Shared Profile Fields
  final String deliveryAddress;
  final Map<String, dynamic>? deliveryAddressMap;
  final String businessName;
  final String bankAccountDetails;
  final String storyAudioUrl;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.languagePreference = 'en',
    this.artisanCluster = '',
    this.region = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.maritalStatus = '',
    this.experienceYears = 0,
    this.profilePhotoUrl = '',
    this.coverPhotoUrl = '',
    this.artisanStory = '',
    this.isProfileCompleted = false,
    this.deliveryAddress = '',
    this.deliveryAddressMap,
    this.businessName = '',
    this.bankAccountDetails = '',
    this.storyAudioUrl = '',
  });

  bool get isArtisan => role == 'artisan';
  bool get isBuyer   => role == 'buyer';

  /// Dynamically computes profile completion percentage based on real Firestore fields.
  /// - Artisan: 10 fields (10% each)
  /// - Buyer: 5 fields (20% each)
  int get profileCompletionPercentage {
    if (isArtisan) {
      int filled = 0;
      if (name.trim().isNotEmpty) filled++;
      if (dateOfBirth.trim().isNotEmpty) filled++;
      if (phone.trim().isNotEmpty) filled++;
      if (gender.trim().isNotEmpty) filled++;
      if (maritalStatus.trim().isNotEmpty) filled++;
      if (experienceYears > 0) filled++;
      if (profilePhotoUrl.trim().isNotEmpty) filled++;
      if (coverPhotoUrl.trim().isNotEmpty) filled++;
      if (artisanStory.trim().isNotEmpty || storyAudioUrl.trim().isNotEmpty) filled++;
      if (bankAccountDetails.trim().isNotEmpty) filled++;
      return (filled * 10).clamp(0, 100);
    } else {
      int filled = 0;
      if (name.trim().isNotEmpty) filled++;
      if (phone.trim().isNotEmpty) filled++;
      if (email.trim().isNotEmpty) filled++;
      if (deliveryAddress.trim().isNotEmpty) filled++;
      if (businessName.trim().isNotEmpty) filled++;
      return (filled * 20).clamp(0, 100);
    }
  }

  /// Creates a [UserModel] from a Firestore document map or API response.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawAddr = json['delivery_address'] ?? json['address'];
    String formattedAddr = '';
    Map<String, dynamic>? addrMap;
    if (rawAddr is Map) {
      addrMap = Map<String, dynamic>.from(rawAddr);
      final parts = <String>[];
      if ((addrMap['name'] ?? '').toString().trim().isNotEmpty) {
        parts.add(addrMap['name'].toString().trim());
      }
      if ((addrMap['phone'] ?? '').toString().trim().isNotEmpty) {
        parts.add(addrMap['phone'].toString().trim());
      }
      if ((addrMap['line1'] ?? '').toString().trim().isNotEmpty) {
        parts.add(addrMap['line1'].toString().trim());
      }
      if ((addrMap['line2'] ?? '').toString().trim().isNotEmpty) {
        parts.add(addrMap['line2'].toString().trim());
      }
      if ((addrMap['city'] ?? '').toString().trim().isNotEmpty) {
        parts.add(addrMap['city'].toString().trim());
      }
      final st = (addrMap['state'] ?? '').toString().trim();
      final pin = (addrMap['pincode'] ?? '').toString().trim();
      if (st.isNotEmpty && pin.isNotEmpty) {
        parts.add('$st - $pin');
      } else if (st.isNotEmpty) {
        parts.add(st);
      } else if (pin.isNotEmpty) {
        parts.add(pin);
      }
      formattedAddr = parts.join(', ');
    } else {
      formattedAddr = rawAddr?.toString() ?? '';
    }

    return UserModel(
      uid:                 json['uid']?.toString() ?? '',
      name:                json['name']?.toString() ?? '',
      email:               json['email']?.toString() ?? '',
      role:                json['role']?.toString() ?? 'buyer',
      phone:               json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
      languagePreference:  json['language_preference']?.toString() ?? 'en',
      artisanCluster:      json['artisan_cluster']?.toString() ?? '',
      region:              json['region']?.toString() ?? '',
      dateOfBirth:         json['date_of_birth']?.toString() ?? '',
      gender:              json['gender']?.toString() ?? '',
      maritalStatus:       json['marital_status']?.toString() ?? '',
      experienceYears:     int.tryParse(json['experience_years']?.toString() ?? '') ?? 0,
      profilePhotoUrl:     json['profile_photo_url']?.toString() ??
                           json['profile_image']?.toString() ??
                           json['avatar_url']?.toString() ??
                           json['avatarUrl']?.toString() ??
                           json['photo_url']?.toString() ??
                           json['photoUrl']?.toString() ??
                           json['imageUrl']?.toString() ??
                           json['profilePhotoUrl']?.toString() ?? '',
      coverPhotoUrl:       json['cover_photo_url']?.toString() ?? '',
      artisanStory:        json['artisan_story']?.toString() ?? json['story']?.toString() ?? '',
      isProfileCompleted:  json['is_profile_completed'] == true,
      deliveryAddress:     formattedAddr,
      deliveryAddressMap:  addrMap,
      businessName:        json['business_name']?.toString() ?? json['organization_name']?.toString() ?? '',
      bankAccountDetails:  json['bank_account_details']?.toString() ?? '',
      storyAudioUrl:       json['story_audio_url']?.toString() ?? '',
    );
  }

  /// Converts this [UserModel] to a JSON map for Firestore / API writes.
  Map<String, dynamic> toJson() => {
    'uid':                  uid,
    'name':                 name,
    'email':                email,
    'role':                 role,
    'phone':                phone,
    'phone_number':         phone,
    'language_preference':  languagePreference,
    'artisan_cluster':      artisanCluster,
    'region':               region,
    'date_of_birth':        dateOfBirth,
    'gender':               gender,
    'marital_status':       maritalStatus,
    'experience_years':     experienceYears,
    'profile_photo_url':    profilePhotoUrl,
    'cover_photo_url':      coverPhotoUrl,
    'artisan_story':        artisanStory,
    'story':                artisanStory,
    'is_profile_completed': isProfileCompleted,
    'delivery_address':     deliveryAddressMap ?? deliveryAddress,
    'business_name':        businessName,
    'bank_account_details': bankAccountDetails,
    'story_audio_url':      storyAudioUrl,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? languagePreference,
    String? artisanCluster,
    String? region,
    String? role,
    String? dateOfBirth,
    String? gender,
    String? maritalStatus,
    int?    experienceYears,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
    String? artisanStory,
    bool?   isProfileCompleted,
    String? deliveryAddress,
    Map<String, dynamic>? deliveryAddressMap,
    String? businessName,
    String? bankAccountDetails,
    String? storyAudioUrl,
  }) {
    return UserModel(
      uid:                 uid,
      email:               email,
      name:                name                ?? this.name,
      role:                role                ?? this.role,
      phone:               phone               ?? this.phone,
      languagePreference:  languagePreference  ?? this.languagePreference,
      artisanCluster:      artisanCluster      ?? this.artisanCluster,
      region:              region              ?? this.region,
      dateOfBirth:         dateOfBirth         ?? this.dateOfBirth,
      gender:              gender              ?? this.gender,
      maritalStatus:       maritalStatus       ?? this.maritalStatus,
      experienceYears:     experienceYears     ?? this.experienceYears,
      profilePhotoUrl:     profilePhotoUrl     ?? this.profilePhotoUrl,
      coverPhotoUrl:       coverPhotoUrl       ?? this.coverPhotoUrl,
      artisanStory:        artisanStory        ?? this.artisanStory,
      isProfileCompleted:  isProfileCompleted   ?? this.isProfileCompleted,
      deliveryAddress:     deliveryAddress     ?? this.deliveryAddress,
      deliveryAddressMap:  deliveryAddressMap  ?? this.deliveryAddressMap,
      businessName:        businessName        ?? this.businessName,
      bankAccountDetails:  bankAccountDetails  ?? this.bankAccountDetails,
      storyAudioUrl:       storyAudioUrl       ?? this.storyAudioUrl,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, role: $role, completed: $isProfileCompleted, percentage: $profileCompletionPercentage%)';
}
