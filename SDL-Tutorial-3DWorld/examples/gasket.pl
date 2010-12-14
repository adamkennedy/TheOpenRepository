#!/usr/bin/perl -w
use strict;
use OpenGL qw/ :all /;

sub myinit {
  # attributes 
  glClearColor(1.0, 1.0, 1.0, 0.0); # white background 
	glColor3f(1.0, 0.0, 0.0); # draw in red 

  # set up viewing 
  # 500 x 500 window with origin lower left 
  glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0.0, 500.0, 0.0, 500.0);
	glMatrixMode(GL_MODELVIEW);
}

sub display {
  # define a point data type 
  my @vertices =([0.0,0.0],[250.0,500.0],[500.0,0.0]); # A triangle 
  my @p =(75.0,50.0);  # An arbitrary initial point  

  glClear(GL_COLOR_BUFFER_BIT);         #clear the window 

  # computes and plots 100,000 new points 

  for( my $i=0; $i<100_000; $i++) {
	  my $j = int rand(3);                # pick a vertex at random 
    # Compute point halfway between vertex and old point 
    $p[0] = ($p[0]+$vertices[$j][0])/2.0; 
	  $p[1] = ($p[1]+$vertices[$j][1])/2.0;
	  # plot new point 
    glBegin(GL_POINTS);
		  glVertex2fv_p(@p); 
	  glEnd();   
	}
	glFlush(); # clear buffers 
}

# Standard GLUT initialization 

glutInit();
glutInitDisplayMode (GLUT_SINGLE | GLUT_RGB); # default, not needed 
glutInitWindowSize(500,500); # 500 x 500 pixel window 
glutInitWindowPosition(0,0); # place window top left on display 
glutCreateWindow("Sierpinski Gasket"); # window title 
glutDisplayFunc(\&display);  # display callback invoked when window opened 

myinit();       # set attributes 

glutMainLoop(); # enter event loop 

__END__