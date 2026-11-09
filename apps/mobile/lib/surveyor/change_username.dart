import 'package:mdosthi_app/login_page.dart';
import 'package:mdosthi_app/surveyor/hamburger_menu.dart';
import 'package:mdosthi_app/surveyor/survery_page_util.dart';
import 'package:mdosthi_app/surveyor/village_data_table_page.dart';
import 'package:mdosthi_app/utils/NetworkSpeedChecker.dart';
import 'package:flutter/material.dart';

class ChangeUserNamePage extends StatefulWidget {
  final String nextPage;
  const ChangeUserNamePage({required this.nextPage, super.key});
  @override
  _ChangeUserNamePageState createState() => _ChangeUserNamePageState();
}

class _ChangeUserNamePageState extends State<ChangeUserNamePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> userNamesList = [];
  List<String> filteredList = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController newUsernameController =
      TextEditingController(); // New controller for adding username
  String selectedCategory = 'User';

  @override
  void initState() {
    super.initState();
    loadUserDetails();
  }

  Future<void> loadUserDetails() async {
    setState(() {
      userNamesList = LoginPage.usernames;
      filteredList = userNamesList;
    });
  }

  void filterFamilyList(String query) {
    setState(() {
      filteredList = userNamesList
          .where(
              (element) => element.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void addUsername(String newUsername) {
    setState(() {
      userNamesList.add(newUsername);
      LoginPage.usernames =
          List.from(userNamesList); // Update LoginPage.usernames
    });
    newUsernameController.clear(); // Clear the text field
  }

  @override
  Widget build(BuildContext context) {
    var dataTable = PaginatedDataTable(
      showCheckboxColumn: false,
      columns: const <DataColumn>[
        DataColumn(label: Text('User')),
      ],
      source: _UserDataSource(
        filteredList,
        onRowClicked: (username) {
          setState(() {
            LoginPage.username = username;
          });
          navigateToFormsPage(
              context, username); // Navigate to details page on row click
        },
      ),
      // header: const Text('Family Details'),
      rowsPerPage: 10,
    );

    List<Widget> content = [dataTable];

    return Scaffold(
      drawer: HamburgerMenu(
        userName: LoginPage.userId,
        email: LoginPage.username,
        pages: const [
          SurveyorPageUtil(),
          LoginPage(),
          NetworkSpeedChecker(),
        ],
        icons: const [
          Icons.home,
          Icons.logout,
          Icons.network_cell_rounded,
        ],
        pageTitles: const ['Home', 'Log out', 'Bandwidth'],
      ),
      appBar: AppBar(
        title: const Text('User Data Table'),
        actions: [
          IconButton(
              onPressed: () => {Navigator.pop(context)},
              icon: const Icon(Icons.arrow_back_rounded)),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (query) {
                        filterFamilyList(query);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Search by $selectedCategory',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Add the entered username to the list
                      String newUsername = searchController.text.trim();
                      if (newUsername.isNotEmpty &&
                          !userNamesList.contains(newUsername)) {
                        addUsername(newUsername);
                        Navigator.pop(context);
                        ///////////////navigate
                        ///
                        //
                        setState(() {
                          LoginPage.username = newUsername;
                        });
                        navigateToFormsPage(context, newUsername);
                      }
                    },
                    child: const Text('Add Username'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height,
                  ),
                  child: ListView(
                    controller: _scrollController,
                    shrinkWrap: true,
                    children: content.map((widget) => widget).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void navigateToFormsPage(BuildContext context, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VillageDataTablePage(nextPage: widget.nextPage),
      ),
    );
  }
}

class UserDetailsPage extends StatelessWidget {
  final String user;

  const UserDetailsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('User : $user'),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserDataSource extends DataTableSource {
  final List<String> _usersList;
  final Function(String) onRowClicked; // Add this callback

  _UserDataSource(this._usersList, {required this.onRowClicked});

  @override
  DataRow? getRow(int index) {
    if (index >= _usersList.length) {
      return null;
    }
    final users = _usersList[index];
    return DataRow(
      cells: [
        DataCell(Text(users)),
      ],
      onSelectChanged: (isSelected) {
        if (isSelected != null && isSelected) {
          onRowClicked(users); // Invoke the callback on row selection
        }
      },
    );
  }

  @override
  int get rowCount => _usersList.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
