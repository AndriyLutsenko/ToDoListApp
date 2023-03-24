import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // await Hive.deleteBoxFromDisk('todoListbox');
  await Hive.openBox('todoListbox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Список справ',
      home: TodoList(),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({Key? key}) : super(key: key);

  @override
  TodoListState createState() => TodoListState();
}

class TodoListState extends State<TodoList> {
  List<Map<String, dynamic>> todosave = [];

  final box = Hive.box('todoListbox');

  @override
  void initState() {
    super.initState();
    loadTodosave(); // загрузка даних при старті
  }

  // Отримання елементів з бази
  void loadTodosave() {
    final data = box.keys.map((key) {
      final value = box.get(key);
      return {
        'key': key,
        'name': value['name'],
        'isDone':
            value['isDone'] ?? false // додати поле isDone, якщо його немає
      };
    }).toList();

    setState(() {
      todosave = data.toList();
    });
  }

  // Створення нового елемента
  Future<void> addTodoElement(Map<String, dynamic> newTodoElement) async {
    await box.add(newTodoElement);
    loadTodosave(); // перезагрузка
  }

  // Оновлення елемента списку
  Future<void> updateTodoElement(
      int todoElementKey, Map<String, dynamic> todoElement) async {
    await box.put(todoElementKey, todoElement);
    loadTodosave(); // перезагрузка списку
  }

  // Відмітка про виконання
  void toggleTodoElement(int todoElementKey) async {
    final todoElement =
        todosave.firstWhere((element) => element['key'] == todoElementKey);
    await updateTodoElement(todoElementKey, {
      'name': todoElement['name'],
      'isDone': !todoElement['isDone'] // змінюємо стан на протилежний
    });
  }

  // Видалення елемента списку
  Future<void> deleteTodoElement(int todoElementKey) async {
    await box.delete(todoElementKey);
    loadTodosave(); // перезагрузка списку

    // Повідомлення про видалення
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Елемент списку справ видалено')));
  }

  final TextEditingController textController = TextEditingController();

  //функція для створення та оновлення елементів списку
  void dialog(BuildContext ctx, int? todoElementKey) async {
    // todoElementKey == null -> створити новий елемент
    // todoElementKey != null -> оновити існуючий елемент
    if (todoElementKey != null) {
      final existingTodoElement =
          todosave.firstWhere((element) => element['key'] == todoElementKey);
      textController.text = existingTodoElement['name'];
    }
    //спливаюче вікно створення/редагування
    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 15,
                  left: 15,
                  right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                        hintText: 'Введіть нове завдання'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Збереження нового елемента
                      if (todoElementKey == null) {
                        addTodoElement({
                          "name": textController.text.trim(),
                        });
                      }
                      // оновлення існуючого
                      if (todoElementKey != null) {
                        updateTodoElement(todoElementKey, {
                          'name': textController.text.trim(),
                        });
                      }
                      textController.clear();

                      Navigator.of(context).pop(); // закрити діалог
                    },
                    child: Text(todoElementKey == null ? 'Додати' : 'Зберегти'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('Список справ'),
      ),
      body: todosave.isEmpty
          ? const Center(
              child: Text(
                'Нічого не заплановано',
                style: TextStyle(fontSize: 24),
              ),
            )
          : ListView.builder(
              //список елементів
              itemCount: todosave.length,
              itemBuilder: (_, index) {
                final currentTodoElement = todosave[index];
                return Card(
                    color: Colors.yellow,
                    // margin: const EdgeInsets.all(5),
                    elevation: 3,
                    child: GestureDetector(
                      onTap: () => toggleTodoElement(currentTodoElement['key']),
                      child: ListTile(
                          title: Text(
                            currentTodoElement['name'],
                            style: TextStyle(
                              decoration: currentTodoElement['isDone']
                                  ? TextDecoration
                                      .lineThrough // якщо елемент відзначений, то закреслюємо текст
                                  : null,
                            ),
                          ),
                          leading: currentTodoElement['isDone']
                              ? const Icon(Icons.check_box_outlined)
                              : CircleAvatar(
                                  child: Text(currentTodoElement['name'].isEmpty
                                      ? '?'
                                      : currentTodoElement['name'][0]),
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Кнопка "Змінити"(ручка)
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => dialog(
                                      context, currentTodoElement['key'])),
                              // Кнопка "Видалити" (корзинка)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => deleteTodoElement(
                                    currentTodoElement['key']),
                              ),
                            ],
                          )),
                    ));
              }),
      // Кнопка для виклику меню додавання
      floatingActionButton: FloatingActionButton(
        onPressed: () => dialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
