import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({Key? key}) : super(key: key);

  @override
  _ContactsViewState createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView>
    with AutomaticKeepAliveClientMixin {
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _getContacts();
  }

  Future<void> _getContacts() async {
    try {
      PermissionStatus permissionStatus = await Permission.contacts.status;

      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.contacts.request();
      }

      if (permissionStatus.isGranted) {
        Iterable<Contact> contacts = await ContactsService.getContacts();
        setState(() {
          _contacts = contacts.toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact permission denied'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get contacts: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return ListTile(
          title: Text(contact.displayName ?? 'No name'),
          subtitle: Text(contact.phones?.isNotEmpty == true
              ? contact.phones!.first.value ?? 'No phone'
              : 'No phone'),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
