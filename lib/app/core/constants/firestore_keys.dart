/// Classe que contém as chaves utilizadas no Firestore
class FirestoreKeys {
  // Collections
  static const String barsCollection = 'bars';
  static const String eventsCollection = 'events';
  static const String vipRequestsCollection = 'vip_requests';
  
  // Bar document fields
  static const String barId = 'id';
  static const String barEmail = 'email';
  static const String barCnpj = 'cnpj';
  static const String barName = 'name';
  static const String barResponsibleName = 'responsible_name';
  static const String barPhone = 'phone';
  static const String barCep = 'cep';
  static const String barStreet = 'street';
  static const String barNumber = 'number';
  static const String barComplement = 'complement';
  static const String barState = 'state';
  static const String barCity = 'city';
  static const String barUserId = 'user_id';
  static const String barCreatedAt = 'created_at';
  static const String barUpdatedAt = 'updated_at';
  
  // Event document fields
  static const String eventId = 'id';
  static const String eventBarId = 'bar_id';
  static const String eventDate = 'date';
  static const String eventAttractions = 'attractions';
  static const String eventPromotions = 'promotions';
  static const String eventPromotionDetails = 'promotion_details';
  static const String eventPromotionImages = 'promotion_images';
  static const String eventAllowVipAccess = 'allow_vip_access';
  static const String eventCreatedAt = 'created_at';
  static const String eventUpdatedAt = 'updated_at';
  
  // VIP request document fields
  static const String vipRequestId = 'id';
  static const String vipRequestEventId = 'event_id';
  static const String vipRequestBarId = 'bar_id';
  static const String vipRequestUserName = 'user_name';
  static const String vipRequestUserEmail = 'user_email';
  static const String vipRequestUserPhone = 'user_phone';
  static const String vipRequestStatus = 'status'; // pending, approved, rejected
  static const String vipRequestCreatedAt = 'created_at';
  static const String vipRequestUpdatedAt = 'updated_at';
  
  // Generic fields
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  
  // Aliases for event fields (for compatibility)
  static const String attractions = eventAttractions;
  static const String promotionImages = eventPromotionImages;
  static const String promotionDetails = eventPromotionDetails;
  static const String allowVipAccess = eventAllowVipAccess;
  
  // Aliases for VIP request fields (for compatibility)
  static const String userId = 'user_id';
  static const String userName = vipRequestUserName;
  static const String userEmail = vipRequestUserEmail;
  static const String userPhone = vipRequestUserPhone;
}