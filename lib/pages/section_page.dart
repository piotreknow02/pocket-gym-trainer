import 'package:PocketGymTrainer/components/workout_controls.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../components/new_item_textfield.dart';
import '../model/exercise.dart';
import '../model/section.dart';
import '../pages/login_page.dart';
import '../services/exercise_service.dart';
import '../services/section_services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../components/section.dart';

class SectionPage extends StatefulWidget {
  const SectionPage({super.key});
  static late var sectionKey;
  static late var sectionName;
  static late int sectionIndex = -1;
  static late List<Exercise> allExercises = <Exercise>[];
  static final GlobalKey<_SectionPageState> sectionPageKey = GlobalKey<_SectionPageState>();

  static _SectionPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_SectionPageState>();
  }

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  List<Exercise> exercises = <Exercise>[];
  Iterable<Exercise> newExercises = <Exercise>[];

  List<Section> sections = <Section>[];
  List<Section> newSections = <Section>[];
  List<Section> newSectionsDelete = <Section>[];
  Section section = Section();
  Section sectionCreate = Section();
  Section sectionDelete = Section();
  Section sectionUpsert = Section();

  final _textController = TextEditingController();
  String userPost = '';
  String sectionName = '';
  bool notClicked = false;
  bool editing = false;
  int selectedSectionIndex = -1;
  int sectionIndex = -1;

  String sectionId = "";
  String? jwtToken = RootPage.token;

  late Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken!);
  late String decodedUserId = decodedToken["id"];

  late List<String> prefsComplete = <String>[];

  Future<void>? enterPrefsFuture;
  bool enterPrefsCalled = false;
  int exercisesLength = 0;

  @override
  void initState() {
    super.initState();
    getData();
    getAllExercises();
    deletePrefs();
    getPrefs();
    enterPrefs();
  }

  //Fills prefComplete with temporary data to be replaced by the completed exercises indexes
  Future<void> enterPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? tempFilled = prefs.getBool('tempFilled');

      if (!enterPrefsCalled) {
        enterPrefsCalled = true;
        enterPrefsFuture = Future.delayed(const Duration(seconds: 1))
            .then((value) => setState(() {
                  for (int i = 0; i < exercises.length; i++) {
                    prefsComplete.add("temp");
                  }
                }));
      }
      tempFilled = true;
      await prefs.setBool('tempFilled', true);
    print(prefsComplete);
    return enterPrefsFuture;
  }

  //Sets both lists index of the completed exercise
  Future<void> setPrefs(int index) async {
    await enterPrefs();
    setState(() {
      prefsComplete[index] = exercises[index].id!;
    });
  }

  //Gets prefs saved in a pref list to know which exercises are already completed
  Future<void> getPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? strList = prefs.getStringList('complete');

    setState(() {
      prefsComplete = strList!;
    });
    print(prefsComplete);
  }

  //All completed exercises are saved into a list of prefs
  Future<void> leavePrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('complete', prefsComplete);
  }

  //Deletes prefs if a workout is not active
  Future<void> deletePrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (WorkoutControls.workoutDone) {
      await prefs.remove('complete');
      Future.delayed(const Duration(milliseconds: 100))
          .then((value) => setState(() {
                WorkoutControls.workoutDone = false;
              }));
    }
  }

  void prefsSet() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if(!RootPage.filledOnce){
      await prefs.setBool('tempFilled', false);
      RootPage.filledOnce = true;
    }
    if(WorkoutControls.workoutDone){
      await prefs.setBool('tempFilled', false);
      RootPage.filledOnce = false;
    }
  }

  void getData() async {
    sections = (await SectionService().getSection(jwtToken!, decodedUserId));
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
  }

  void createData() async {
    print(sectionCreate.name);
    section = (await SectionService().createSection(sectionCreate))!;
    sections.add(section);
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
  }

  void deleteData(String sectionId) async {
    await SectionService().deleteSection(sectionId, jwtToken!);
    getData();
    sectionDelete.id = sectionId;
    newSectionsDelete = sections;
    newSectionsDelete.remove(sectionDelete);
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
  }

  void upsertData(String sectionId) async {
    section = (await SectionService().upsertSection(sectionId, sectionUpsert))!;
    getData();
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
  }

  Future<void> addSection() async {
    setState(() {
      userPost = _textController.text;
      sectionCreate.name = userPost;
      sectionCreate.userId = decodedUserId;
      sectionCreate.exercisesPerformed = 0;
      createData();
      Future.delayed(const Duration(milliseconds: 10))
          .then((value) => setState(() {}));
      notClicked = false;
      _textController.text = "";
    });
  }

  void deleteSection(String id) {
    setState(() {
      sectionId = id;
      deleteData(sectionId);
      sections = newSectionsDelete;
    });
  }

  void editSection(String id, int index) async {
    setState(() {
      userPost = _textController.text;
      sectionUpsert.name = userPost;
      sectionUpsert.userId = decodedUserId;
      sectionUpsert.exercisesPerformed = sections[index].exercisesPerformed;
      editing = false;
      sectionId = id;
      upsertData(sectionId);
      getData();
      sections = newSections;
      _textController.text = "";
    });
  }

  void getAllExercises() async {
    exercises = (await ExerciseService().getAllExercises(decodedUserId));
    SectionPage.allExercises = exercises;
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
  }

  exercisesCountDisplay(int index) {
    newExercises =
        exercises.where((element) => element.sectionId == sections[index].id);
    return newExercises.length;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.only(top: 5),
      child: Stack(
        children: <Widget>[
          ListView.builder(
            itemBuilder: (context, index) {
              return Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(
                        left: 20,
                        top: 10,
                        right: 20,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 110,
                        child: Slidable(
                          closeOnScroll: true,
                          child: Container(
                            width: double.infinity,
                            height: 110,
                            child: ElevatedButton(
                              onPressed: () {
                                SectionPage.sectionKey = sections[index].id;
                                SectionPage.sectionName = sections[index].name;
                                editing = false;
                                selectedSectionIndex = -1;
                                prefsSet();
                                context.push('/exercises');
                              },
                              child: !editing || selectedSectionIndex != index
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Container(
                                            margin: EdgeInsets.only(left: 50),
                                            child: Center(
                                              child: AutoSizeText(
                                                sections[index].name!,
                                                style: const TextStyle(
                                                  fontSize: 70,
                                                ),
                                                minFontSize: 40,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        RootPage.workoutStarted
                                            ? Expanded(
                                                child: Align(
                                                  alignment: Alignment.topRight,
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                        top: 20),
                                                    child: exercises.any(
                                                            (element) =>
                                                                element
                                                                    .sectionId ==
                                                                sections[index]
                                                                    .id)
                                                        ? Text(
                                                            "0/${exercisesCountDisplay(index)}",
                                                            style: TextStyle(
                                                                fontSize: 17),
                                                          )
                                                        : Text("0/0"),
                                                  ),
                                                ),
                                              )
                                            : Expanded(
                                                child: Container(
                                                  margin:
                                                      EdgeInsets.only(top: 20),
                                                ),
                                              )
                                      ],
                                    )
                                  : Container(
                                      margin: const EdgeInsets.only(
                                          left: 7, right: 10),
                                      child: TextField(
                                        cursorColor: Colors.white,
                                        autofocus: true,
                                        controller: _textController,
                                        style: TextStyle(
                                          fontSize: 50,
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.white,
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            color: Colors.white,
                                            onPressed: () {
                                              sectionIndex = index;
                                              editSection(sections[index].id!,
                                                  sectionIndex);
                                              _textController.text = "";
                                            },
                                            icon: Icon(
                                              Icons.done,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          startActionPane: ActionPane(
                            extentRatio: 0.15,
                            motion: ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) => setState(() {
                                  if (!editing) {
                                    editing = true;
                                    _textController.text =
                                        sections[index].name!;
                                    selectedSectionIndex = index;
                                  } else {
                                    if (selectedSectionIndex != index) {
                                      editing = true;
                                      _textController.text =
                                          sections[index].name!;
                                      selectedSectionIndex = index;
                                    } else {
                                      editing = false;
                                      _textController.text = "";
                                      selectedSectionIndex = -1;
                                    }
                                  }
                                }),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: !editing || selectedSectionIndex != index
                                    ? Icons.edit
                                    : Icons.subdirectory_arrow_left_sharp,
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            extentRatio: 0.2,
                            motion: ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) =>
                                    deleteSection(sections[index].id!),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete_sharp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
            itemCount: sections.length,
          ),
          NewItemTextField(
            text: "Name of a new section",
            notClicked: notClicked,
            textController: _textController,
            onClicked: () {
              setState(() {
                notClicked = !notClicked;
              });
            },
            addElement: addSection,
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            iconColor: Color.fromARGB(255, 0, 0, 0),
          )
        ],
      ),
    );
  }
}
