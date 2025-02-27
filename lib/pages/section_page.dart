import 'package:PocketGymTrainer/components/workout_controls.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/empty_list.dart';
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
  static late var exercisesPerformed;
  static late int sectionIndex = -1;
  static late int exercisesCountedLength = -1;
  static late List<Exercise> certainExercises = <Exercise>[];
  static late List<Exercise> allExercises = <Exercise>[];
  static final GlobalKey<_SectionPageState> sectionPageKey =
      GlobalKey<_SectionPageState>();

  static _SectionPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_SectionPageState>();
  }

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  List<Exercise> exercises = <Exercise>[];
  List<Exercise> newExercises = <Exercise>[];
  List<Exercise> exercisesDelete = <Exercise>[];
  List<Exercise> exercisesCounted = <Exercise>[];
  List<Exercise> certainExercises = <Exercise>[];

  List<Section> sections = <Section>[];
  List<Section> newSections = <Section>[];
  List<Section> newSectionsDelete = <Section>[];
  List<Section> certainSections = <Section>[];
  Section section = Section();
  Section sectionCreate = Section();
  Section sectionDelete = Section();
  Section sectionUpsert = Section();

  final _textController = TextEditingController();
  String userPost = '';
  String sectionName = '';
  double opacity = 0;
  bool editing = false;
  int selectedSectionIndex = -1;

  String sectionId = "";
  String? jwtToken = RootPage.token;

  late Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken!);
  late String decodedUserId = decodedToken["id"];

  late List<String> prefsComplete = <String>[];

  Future<void>? enterPrefsFuture;
  bool enterPrefsCalled = false;
  int exercisesLength = 0;

  Future<List<Section>>? sectionsData;

  @override
  void initState() {
    super.initState();
    getData();
    deletePrefs();
    getAllExercises();
    exercisesCompleted();
  }

  void getData() async {
    await (sectionsData =
        SectionService().getSection(jwtToken!, decodedUserId));
    sections = (await sectionsData) ?? [];
    setState(() {
      sections = sections..sort((s1, s2) => s1.name!.compareTo(s2.name!));
    });

    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {
              RootPage.sectionsLength = sections.length;
            }));
  }

  void createData() async {
    section = (await SectionService().createSection(sectionCreate));
    if (section.id == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Container(
                padding: EdgeInsets.only(right: 10, bottom: 10),
                child: Text(
                  "Close",
                  style: TextStyle(fontSize: 17),
                ),
              ),
            )
          ],
          title: const Text("Too many sections"),
          content: const Text("Max amount is 10"),
          contentPadding: const EdgeInsets.all(25.0),
        ),
      );
    } else {
      sections.add(section);
      RootPage.sectionsLength++;
    }
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
    //countedExercises(sections.length-1);
  }

  void deleteData(String sectionId) async {
    await SectionService().deleteSection(sectionId, jwtToken!);
    getData();
    deleteExercise(sectionId);
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
      opacity = 0;
      _textController.text = "";
    });
  }

  void deleteExercise(String sectionId) async {
    await ExerciseService().deleteExerciseList(sectionId);
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
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
    setState(() {
      SectionPage.allExercises = exercises;
    });
    Future.delayed(const Duration(milliseconds: 10))
        .then((value) => setState(() {}));
  }

  exercisesCountDisplay(int index) {
    newExercises = exercises
        .where((element) => element.sectionId == sections[index].id)
        .toList();
    return newExercises.length;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        FutureBuilder(
          future: sectionsData,
          builder: ((context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemBuilder: (context, index) {
                    return Column(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(
                            left: 20,
                            top: 10,
                            right: 20,
                          ),
                          child: Slidable(
                            enabled: !RootPage.workoutStarted,
                            closeOnScroll: true,
                            child: SectionComponent(
                              sections: sections,
                              exercises: exercises,
                              textController: _textController,
                              sectionClicked: () {
                                SectionPage.sectionKey = sections[index].id;
                                SectionPage.sectionName = sections[index].name;
                                SectionPage.exercisesPerformed =
                                    sections[index].exercisesPerformed;
                                SectionPage.sectionIndex = index;
                                editing = false;
                                selectedSectionIndex = -1;
                                countedExercises(index);
                                exercisesCompleted();
                                opacity = 0;
                                context.push('/exercises');
                              },
                              sectionEdited: () {
                                editSection(sections[index].id!, index);
                                _textController.text = "";
                              },
                              exercisesCountDisplay: (index) {
                                newExercises = exercises
                                    .where((element) =>
                                        element.sectionId == sections[index].id)
                                    .toList();
                                return newExercises.length;
                              },
                              editing: editing,
                              selectedSectionIndex: selectedSectionIndex,
                              certainIndex: index,
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
                                  icon:
                                      !editing || selectedSectionIndex != index
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
                                  onPressed: (context) {
                                    if (sections[index].exercisesPerformed! >
                                        0) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                deleteSection(
                                                    sections[index].id!);
                                                context.pop();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.only(
                                                    right: 10, bottom: 10),
                                                child: Text(
                                                  "Delete anyway",
                                                  style:
                                                      TextStyle(fontSize: 17),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                context.pop();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.only(
                                                  right: 10,
                                                  bottom: 5,
                                                ),
                                                child: Text(
                                                  "Cancel",
                                                  style:
                                                      TextStyle(fontSize: 17),
                                                ),
                                              ),
                                            ),
                                          ],
                                          title: Text(
                                              "Exercise data of ${sections[index].name}"),
                                          content: const Text(
                                            "After deleting this section, data used in the radar chart will be lost!",
                                          ),
                                          contentPadding:
                                              const EdgeInsets.all(25.0),
                                        ),
                                      );
                                    } else {
                                      deleteSection(sections[index].id!);
                                    }
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_sharp,
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    );
                  },
                  itemCount: sections.length,
                );
              } else {
                return EmptyList(
                  imagePath: "images/push-up.png",
                  text:
                      "Click the button in right bottom\nto add new exercise sections",
                );
              }
            } else {
              return Center(
                child: SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                  ),
                ),
              );
            }
          }),
        ),
        NewItemTextField(
          text: "Name of a new section",
          opacity: opacity,
          textController: _textController,
          onClicked: () {
            setState(() {
              if (opacity == 0) {
                opacity = 1;
              } else {
                opacity = 0;
              }
            });
          },
          addElement: addSection,
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          iconColor: Color.fromARGB(255, 0, 0, 0),
        )
      ],
    );
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

  void countedExercises(int index) {
    if (index > 0) {
      exercisesCounted = exercises.where((element) {
        int sectionIndex =
            sections.indexWhere((section) => section.id == element.sectionId);
        return sectionIndex >= 0 && sectionIndex < index;
      }).toList();
      SectionPage.exercisesCountedLength = exercisesCounted.length;
    } else {
      SectionPage.exercisesCountedLength = 0;
    }
  }

  void exercisesCompleted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? strList = prefs.getStringList('complete') ?? [];
    //It adds into the list but prefs reset only when i enter the exercises

    setState(() {
      prefsComplete = strList;
    });

    certainExercises = exercises.where((element) {
      return strList.contains(element.sectionId);
    }).toList();

    certainSections = sections.where((section) {
      return certainExercises
          .any((exercise) => section.id == exercise.sectionId);
    }).toList();
    SectionPage.certainExercises = certainExercises;
  }
}
