// Returns 0 if the desktop is available, 1 otherwise.
// Also spews errors on stderr in the latter case.
// Don't forget java 1.7 and AWT_TOOLKIT=CToolkit

import java.awt.*;
import java.awt.event.*;
import java.util.concurrent.*;

public class TestDesktop implements Callable<Void> {
  public static void main(String argv[]) {
    Executors.newSingleThreadExecutor().submit(new TestDesktop());
    Frame f = new Frame( "Hello world!" );
    System.exit(0);
  }
  public Void call() {
    try {
      Thread.sleep(5000);
    } catch (Exception e) { }
    System.exit(1);
    return null;
  }
}
