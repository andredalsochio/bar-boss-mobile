/// Classe que contém as chaves utilizadas no Firestore para o modelo multi-bar/multi-usuário
class FirestoreKeys {
  // Collections
  static const String usersCollection = 'users';
  static const String barsCollection = 'bars';
  static const String membersSubcollection = 'members';
  static const String eventsSubcollection = 'events';
  static const String cnpjRegistryCollection = 'cnpj_registry';
  
  // User document fields (/users/{uid})
  static const String userEmail = 'email';
  static const String userDisplayName = 'displayName';
  static const String userPhotoUrl = 'photoUrl';
  static const String userProviders = 'providers';
  static const String userCurrentBarId = 'currentBarId';
  static const String userCreatedAt = 'createdAt';
  static const String userLastLoginAt = 'lastLoginAt';
  
  // Bar document fields (/bars/{barId})
  static const String barName = 'name';
  static const String barCnpj = 'cnpj';
  static const String barResponsibleName = 'responsibleName';
  static const String barContactEmail = 'contactEmail';
  static const String barContactPhone = 'contactPhone';
  static const String barAddress = 'address';
  static const String barProfile = 'profile';
  static const String barStatus = 'status';
  static const String barLogoUrl = 'logoUrl';
  static const String barCreatedAt = 'createdAt';
  static const String barUpdatedAt = 'updatedAt';
  static const String barCreatedByUid = 'createdByUid';
  static const String barPrimaryOwnerUid = 'primaryOwnerUid';
  
  // Bar address fields (nested in address map)
  static const String addressCep = 'cep';
  static const String addressStreet = 'street';
  static const String addressNumber = 'number';
  static const String addressComplement = 'complement';
  static const String addressState = 'state';
  static const String addressCity = 'city';
  
  // Bar profile fields (nested in profile map)
  static const String profileContactsComplete = 'contactsComplete';
  static const String profileAddressComplete = 'addressComplete';
  
  // Member document fields (/bars/{barId}/members/{uid})
  static const String memberUid = 'uid';
  static const String memberRole = 'role';
  static const String memberInvitedByUid = 'invitedByUid';
  static const String memberCreatedAt = 'createdAt';
  
  // Event document fields (/bars/{barId}/events/{eventId})
  static const String eventBarId = 'barId';
  static const String eventTitle = 'title';
  static const String eventStartAt = 'startAt';
  static const String eventEndAt = 'endAt';
  static const String eventDescription = 'description';
  static const String eventAttractions = 'attractions';
  static const String eventCoverImageUrl = 'coverImageUrl';
  static const String eventPublished = 'published';
  static const String eventCreatedAt = 'createdAt';
  static const String eventUpdatedAt = 'updatedAt';
  static const String eventCreatedByUid = 'createdByUid';
  static const String eventUpdatedByUid = 'updatedByUid';
  
  // Event promotion fields
  static const String eventPromoDetails = 'promoDetails';
  static const String eventPromoImages = 'promoImages';
  
  // CNPJ Registry document fields (/cnpj_registry/{cnpj})
  static const String cnpjRegistryBarId = 'barId';
  static const String cnpjRegistryReservedByUid = 'reservedByUid';
  static const String cnpjRegistryCreatedAt = 'createdAt';
  
  // Generic fields
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  
  // Member roles
  static const String roleOwner = 'OWNER';
  static const String roleAdmin = 'ADMIN';
  static const String roleEditor = 'EDITOR';
  
  // Bar status values
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusPending = 'pending';
  
  // Backward compatibility aliases (deprecated - will be removed)
  @deprecated
  static const String barId = 'id';
  @deprecated
  static const String barEmail = 'email';
  @deprecated
  static const String barPhone = 'phone';
  @deprecated
  static const String barCep = 'cep';
  @deprecated
  static const String barStreet = 'street';
  @deprecated
  static const String barNumber = 'number';
  @deprecated
  static const String barComplement = 'complement';
  @deprecated
  static const String barState = 'state';
  @deprecated
  static const String barCity = 'city';
  @deprecated
  static const String eventDate = 'date';
  @deprecated
  static const String attractions = eventAttractions;
}