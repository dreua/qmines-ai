#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QLoggingCategory>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/MineAI.qml")));
    qDebug() << "Started";
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
