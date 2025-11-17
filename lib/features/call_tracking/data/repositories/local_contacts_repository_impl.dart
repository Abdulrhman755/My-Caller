import '../../domain/repositories/local_contacts_repository.dart';
import '../datasources/local_database_datasource.dart'; // استيراد خدمة الداتابيز

// (التنفيذ) Implementation
class LocalContactsRepositoryImpl implements LocalContactsRepository {
  final DatabaseService databaseService;

  LocalContactsRepositoryImpl({required this.databaseService});

  @override
  Future<void> saveContact(String number, String name) async {
    final contact = SavedContact(number: number, name: name);
    await databaseService.insertContact(contact);
  }

  @override
  Future<String?> getNameForNumber(String number) async {
    final contact = await databaseService.getContactByNumber(number);
    return contact?.name;
  }
}