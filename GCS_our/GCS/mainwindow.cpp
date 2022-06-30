#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QPushButton>
#include "mypushbutton.h"
#include <QDebug>
#include <QMenuBar>
#include <QToolBar>
#include <QStatusBar>
#include <QLabel>
#include <QDockWidget>
#include <QTextEdit>
#include <QIcon>
#include <QAction>
#include <QDialog>
#include <QMessageBox>
#include <QColorDialog>
#include <QColor>
#include <QFileDialog>
#include <QFontDialog>
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
//    QPushButton * button1 = new QPushButton("open", this);
//    button1->resize(200,100);
//    button1->move(200,100);
//    connect(button1, &QPushButton::clicked, this, &MainWindow::close);
//    QPushButton * button2 = new QPushButton("close", this);
//    button2->resize(200,100);
//    button2->move(200,200);

//    MyPushButton * myButton = new MyPushButton;
//    myButton->setParent(this);
//    myButton->setText("my button");
//    myButton->resize(200,100);
//    myButton->move(400,400);
//    this->ljb = new Teacher(this);
//    this->ddy = new Student(this);

//    void(Teacher:: *teacherSignal)(QString) = &Teacher::hungry;
//    void(Student:: *studentSlot)(QString) = &Student::treat;
//    connect(ljb, teacherSignal, ddy, studentSlot);

//   connect(button1, &QPushButton::clicked, this, &MainWindow::classIsOver);

//    void(Teacher:: *teacherSignal2)(void) = &Teacher::hungry;
//    void(Student:: *studentSlot2)(void) = &Student::treat;
//    connect(ljb, teacherSignal2, ddy, studentSlot2);

//    connect(button1, &QPushButton::clicked, ljb, teacherSignal2);
//    disconnect(ljb, teacherSignal2, ddy, studentSlot2);

//    [=](){
//        button1->setText("lamda expression");
//    }();
    // [m]()mutable{m = m+10}
    // []()->int(return   )

//    connect(button1, &QPushButton::clicked, this, [=](){
//        emit ljb->hungry("gong bao ji ding");
//        button1->show();
//    });

//    first homework
//    QMainWindow * one = new QMainWindow;  // cannot use new MainWindow
//    one->setFixedSize(600,400);
//    connect(button1, &QPushButton::clicked, [=](){one->show();});
//    connect(button2, &QPushButton::clicked, [=](){
//        if(button2->text()=="close")
//        {
//            one->close();
//            button2->setText("open");
//        }else
//        {
//            one->show();
//            button2->setText("close");
//        }
//    });
//    resize(600,400);

    //menu bar
//    QMenuBar * bar = menuBar();
//    setMenuBar(bar);
//    QMenu * fileMenu = bar->addMenu("File");
//    QMenu * editMenu = bar->addMenu("Edit");
//    QAction * newAction = fileMenu->addAction("new");
//    fileMenu->addSeparator();
//    QAction * openAction = fileMenu->addAction("open");

//    //Tool bar
//    QToolBar * toolBar = new QToolBar(this);
//    addToolBar(Qt::LeftToolBarArea, toolBar);
//    toolBar->setAllowedAreas(Qt::LeftToolBarArea | Qt::RightToolBarArea);
//    toolBar->setFloatable(false);
//    toolBar->addAction(newAction);
//    toolBar->addSeparator();
//    toolBar->addAction(openAction);

//    QPushButton * button3 = new QPushButton("aa", this);
//    toolBar->addWidget(button3);

//    //status bar
//    QStatusBar * statusBar = new QStatusBar(this);
//    setStatusBar(statusBar);
//    QLabel * label = new QLabel("status",this);
//    statusBar->addWidget(label);

//    //floatable window
//    QDockWidget * dockWidget = new QDockWidget("float", this);
//    addDockWidget(Qt::BottomDockWidgetArea, dockWidget);

//    //central widget
//    QTextEdit * edit = new QTextEdit(this);
//    setCentralWidget(edit);

    //ui and add resource
//    ui->actionnew->setIcon(QIcon(":/Pictures/Screenshot from 2022-05-09 11-12-33.png"));

    //dialog
//    QDialog * dlg2 = new QDialog(this);
//    connect(ui->actionnew, &QAction::triggered, [=](){
//        QDialog dlg(this);
//        dlg.resize(200,100);
//        dlg.exec();
//        dlg2->setAttribute(Qt::WA_DeleteOnClose);
//        dlg2->show();
//    });

    // message
//    QMessageBox::critical(this, "critical", "error");
//    QMessageBox::information(this, "tutu", "info");
//    connect(ui->actionnew, &QAction::triggered, [=](){
//    if(QMessageBox::Save == QMessageBox::question(this, "tutu", "ceshi", QMessageBox::Save|QMessageBox::Cancel))
//    {
//        qDebug()<<"save";
//    }else
//    {
//        qDebug()<<"cancel";
//    }
//    QMessageBox::warning(this, "warning", "fur");
//        color
//        QColor color = QColorDialog::getColor(QColor(255,0,0));
//        qDebug() << "r = " << color.red() << "g = " << color.green() << "b = " << color.blue();
//        QString str = QFileDialog::getOpenFileName(this, "open file", "/home/tutu", "*.txt");
//        bool flag;
//    QFontDialog::getFont(&flag,this);
//    });

//        connect(ui->femaleButton,&QRadioButton::clicked, [=](){
//qDebug()<<"choose female";
//        });

//        connect(ui->dengyan,&QCheckBox::stateChanged,[=](int state){
//            qDebug()<<state;
//        });

//        QListWidgetItem * item = new QListWidgetItem("lalala");
//        ui->listWidget->addItem(item);
//        item->setTextAlignment(Qt::AlignHCenter);

//          QStringList list;
//          list << "jdieud" << "djeiude";
//          ui->listWidget->addItems(list);

//          ui->treeWidget->setHeaderLabels(QStringList()<<"tutu"<<"zijun");
//          QTreeWidgetItem * liliang  = new QTreeWidgetItem(QStringList()<<"liliang");
//          ui->treeWidget->addTopLevelItem(liliang);

//          QTreeWidgetItem * jia  = new QTreeWidgetItem(QStringList()<<"jia");
//          liliang->addChild(jia);

//          ui->tableWidget->setColumnCount(3);
//          ui->tableWidget->setHorizontalHeaderLabels(QStringList()<<"name"<<"sex"<<"age");
//          ui->tableWidget->setRowCount(5);
//          ui->tableWidget->setItem(0,0,new QTableWidgetItem("yase"));
//          QStringList nameList, sexList, ageList;
//          nameList<<"liubei"<<"zhugeliang"<<"zhaoyun"<<"guanyu"<<"zhangfei";
//          sexList<<"male"<<"male"<<"male"<<"male"<<"male";
//          for(int i=0; i<5; i++)
//          {
//              int col = 0;
//              ui->tableWidget->setItem(i, col++, new QTableWidgetItem(nameList[i]));
//              ui->tableWidget->setItem(i, col++, new QTableWidgetItem(sexList[i]));
//              ui->tableWidget->setItem(i, col++, new QTableWidgetItem(QString::number(i+18)));
//          }

          connect(ui->btnTutu, &QPushButton::clicked, [=](){
              ui->stackedWidget->setCurrentIndex(1);
          });

          connect(ui->btnZijun, &QPushButton::clicked, [=](){
              ui->stackedWidget->setCurrentIndex(2);
          });


          connect(ui->btnDengyan, &QPushButton::clicked, [=](){
              ui->stackedWidget->setCurrentIndex(0);
          });

          ui->labelImage->setPixmap(QPixmap(":/Pictures/Screenshot from 2022-05-12 21-39-42.png"));

}

void MainWindow:: classIsOver()
{
//    emit ljb->hungry();
    emit ljb->hungry("gong bao ji ding");
}

MainWindow::~MainWindow()
{
    delete ui;
}

