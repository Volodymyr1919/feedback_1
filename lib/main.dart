import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Аутентификация'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  User? user = await _signInWithGoogle();
                  if (user != null) {
                    // Перейти на страницу отзывов после успешной аутентификации.
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FeedbackScreen(user: user)));
                  }
                },
                child: Text('Войти с помощью Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedbackScreen extends StatefulWidget {

  final User? user;

  FeedbackScreen({this.user});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<FeedbackItem> feedbackList = [];

  void _showFeedbackDialog() {
    int? selectedRating; // Локальная переменная для хранения рейтинга
    String? work; // Локальная переменная для названия работы
    String? comment; // Локальная переменная для комментария

    TextEditingController workController = TextEditingController();
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Оставить отзыв'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: workController,
                decoration: InputDecoration(labelText: 'Название работы'),
                onChanged: (value) {
                  work = value;
                },
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: 'Комментарий'),
                onChanged: (value) {
                  comment = value;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Оценка: '),
                  StarRating(
                    rating: selectedRating ?? 0,
                    onRatingChanged: (rating) {
                      setState(() {
                        selectedRating = rating.toInt();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отправить'),
              onPressed: () {
                setState(() {
                  if (selectedRating != null && work != null && comment != null) {
                    feedbackList.add(
                      FeedbackItem(
                        rating: selectedRating!,
                        work: work!,
                        comment: comment!,
                      ),
                    );
                  }
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback App'),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: _showFeedbackDialog,
            child: Text('Оставить отзыв'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Рейтинг: ${feedbackList[index].rating}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Название работы: ${feedbackList[index].work}'),
                      Text('Комментарий: ${feedbackList[index].comment}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackItem {
  final int rating;
  final String work;
  final String comment;

  FeedbackItem({
    required this.rating,
    required this.work,
    required this.comment,
  });
}

class StarRating extends StatefulWidget {
  final int rating;
  final Function(double) onRatingChanged;

  StarRating({required this.rating, required this.onRatingChanged});

  @override
  _StarRatingState createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  double _currentRating = 0;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return InkWell(
          onTap: () {
            widget.onRatingChanged(index + 1.0);
            setState(() {
              _currentRating = index + 1.0;
            });
          },
          child: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            color: Colors.yellow,
          ),
        );
      }),
    );
  }
}