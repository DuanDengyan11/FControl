#include "student.h"
#include<QDebug>
Student::Student(QObject *parent)
    : QObject{parent}
{

}

void Student::treat()
{
    qDebug() << "treat the teacher";
}

void Student::treat(QString foodname)
{
    qDebug() << "treat the teacher with" << foodname.toUtf8().data();
}
