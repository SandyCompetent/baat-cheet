import 'package:flutter/material.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.redAccent,
          child: Center(
            child: Column(
              children: <Widget>[
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(
                    top: 30,
                    bottom: 10,
                  ),
                  child: const Material(
                    borderRadius: BorderRadius.all(Radius.circular(50.0)),
                    child: Image(
                      image: AssetImage('assets/app_logo.png'),
                    ),
                  ),
                ),
                const Text(
                  'Sandeep Malviya',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  height: 40.0,
                ),
                const Text(
                  'Founder and CEO of SandyTech "Lets get started"',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        CustomListTile('Email Address', () => {}),
        CustomListTile('Telephone', () => {}),
        CustomListTile('Notification', () => {}),
        CustomListTile('Settings', () => {}),
        CustomListTile('Feedback', () => {}),
        CustomListTile('Get help', () => {}),
      ],
    );
  }
}

class CustomListTile extends StatelessWidget {
  final String text;
  final Function() onTap;

  const CustomListTile(this.text, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
      child: Container(
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade400))),
        child: InkWell(
          splashColor: Colors.redAccent,
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_right)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
