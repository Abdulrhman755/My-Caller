// (العقد) Abstract
abstract class LocalContactsRepository {
  Future<void> saveContact(String number, String name);
  Future<String?> getNameForNumber(String number);
}