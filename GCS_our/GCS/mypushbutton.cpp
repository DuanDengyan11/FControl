#include "mypushbutton.h"
#include <QDebug>

MyPushButton::MyPushButton(QWidget *parent)
    : QPushButton{parent}
{
    qDebug()<<"create my push button";
}

MyPushButton::~MyPushButton()
{
    qDebug()<<"clean my push button";
}
