#include "mainwindow.h"

#include <QApplication> // include QApplication class

// argument count, argument vector
int main(int argc, char *argv[])
{
    QApplication a(argc, argv); // create application object
    MainWindow w; // window object
    w.show(); // show
    return a.exec(); //loop
}
