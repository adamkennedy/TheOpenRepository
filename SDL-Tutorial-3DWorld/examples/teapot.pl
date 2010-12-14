#!/usr/local/bin/perl
use strict;
use warnings;

use OpenGL qw/ :all /;

my $spin = 0.0;
my $toggle = 0;

my @light0_position = (2.0, 8.0, 2.0, 0.0);
my @mat_specular    = (1.0, 1.0, 1.0, 1.0);
my @mat_shininess        = (50.0);
my @mat_amb_diff_color     = (0.5, 0.7, 0.5, 0.5);
my @light_diffuse = (1.0, 1.0, 1.0, 1.0);
my @light_ambient = (0.15, 0.15, 0.15, 0.15);
my @light_specular = (1.0, 1.0, 1.0, 1.0);

sub init {
  glClearColor(1.0, 1.0, 1.0, 1.0);
  glShadeModel(GL_SMOOTH);   
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);  
}

sub display {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glLightfv_p(GL_LIGHT0, GL_POSITION, @light0_position);
  glLightfv_p(GL_LIGHT0, GL_DIFFUSE, @light_diffuse);
  glLightfv_p(GL_LIGHT0, GL_AMBIENT, @light_ambient); 
  glLightfv_p(GL_LIGHT0, GL_SPECULAR, @light_specular);
  glMaterialfv_p(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @mat_amb_diff_color);
  glLoadIdentity();
  gluLookAt(2.0, 4.0, 10.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
  glPushMatrix();
  glScalef(2.0, 2.0, 2.0);
  glRotatef($spin, 0.0, 1.0, 0.0);
  glutSolidTeapot(1.0);
  glPopMatrix();
  glutSwapBuffers();
}

sub reshape {
  my ($w, $h) = @_;
  glViewport(0, 0, $w, $h);
  glMatrixMode (GL_PROJECTION);	
  glLoadIdentity ();	#  define the projection
  gluPerspective(45.0, $h ? $w/$h : 0, 1.0, 20.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
}

sub spinDisplay {
  $spin += 1.0;
  $spin = $spin - 360.0 if ($spin >360.0);
  glutPostRedisplay();
}

sub mouse {
  my ($button, $state, $x, $y) = @_;
  if ($button == GLUT_LEFT_BUTTON) {
    glutIdleFunc(\&spinDisplay) if ($state == GLUT_DOWN);
  }
  elsif ($button == GLUT_RIGHT_BUTTON) {
    glutIdleFunc(undef) if ($state == GLUT_DOWN);
  }
}

glutInit();
glutInitDisplayMode (GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
glutInitWindowPosition (0, 0);
glutInitWindowSize(300, 300);
glutCreateWindow ("Teapot");
init ();
glutDisplayFunc(\&display);
glutReshapeFunc(\&reshape);
glutMouseFunc(\&mouse);
glutIdleFunc(\&spinDisplay);
glutMainLoop();
  
__END__