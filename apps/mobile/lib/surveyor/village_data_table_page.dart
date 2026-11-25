import 'package:mdosthi_app/login_page.dart';
import 'package:mdosthi_app/surveyor/form_selection_survey.dart';
import 'package:mdosthi_app/surveyor/hamburger_menu.dart';
import 'package:mdosthi_app/surveyor/survery_page_util.dart';
import 'package:mdosthi_app/utils/NetworkSpeedChecker.dart';
import 'package:flutter/material.dart';
import 'package:mdosthi_app/backend/database_helper.dart';

class VillageDataTablePage extends StatefulWidget {
  final String nextPage;
  const VillageDataTablePage({required this.nextPage, super.key});
  @override
  _VillageDataTablePageState createState() => _VillageDataTablePageState();
}

class _VillageDataTablePageState extends State<VillageDataTablePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> Villages = [];
  List<String> filteredList = [];
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'Village';

  @override
  void initState() {
    super.initState();
    loadVillageDetails();
  }

  Future<void> loadVillageDetails() async {
    final dbHelper = DatabaseHelper.instance;
    final villageDetails = await dbHelper.getVillageNames();

    setState(() {
      Villages = villageDetails
          .map(
            (village) => village['Village'].toString(),
          )
          .toList();
      filteredList = Villages;
    });
  }

  void filterFamilyList(String query) {
    setState(() {
      filteredList = Villages.where(
              (element) => element.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    var dataTable = PaginatedDataTable(
      showCheckboxColumn: false,
      columns: const <DataColumn>[
        DataColumn(label: Text('Village')),
      ],
      source: _VillageDataSource(
        filteredList,
        onRowClicked: (village) {
          navigateToFormsPage(
              context, village); // Navigate to details page on row click
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
        title: const Text('Village Data Table'),
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

  void navigateToFormsPage(BuildContext context, String village) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FormDataTablePage(village: village, nextPage: widget.nextPage),
      ),
    );
  }
}

class VillageDetailsPage extends StatelessWidget {
  final String village;

  const VillageDetailsPage({super.key, required this.village});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Village Details'),
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Village : $village'),
            ],
          ),
        ),
      ),
    );
  }
}

class _VillageDataSource extends DataTableSource {
  final List<String> _villageList;
  final Function(String) onRowClicked; // Add this callback

  _VillageDataSource(this._villageList, {required this.onRowClicked});

  @override
  DataRow? getRow(int index) {
    if (index >= _villageList.length) {
      return null;
    }
    final village = _villageList[index];
    return DataRow(
      cells: [
        DataCell(Text(village)),
      ],
      onSelectChanged: (isSelected) {
        if (isSelected != null && isSelected) {
          onRowClicked(village); // Invoke the callback on row selection
        }
      },
    );
  }

  @override
  int get rowCount => _villageList.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
