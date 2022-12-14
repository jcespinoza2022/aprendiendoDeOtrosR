#
# fields  is a package for analysis of spatial data written for
# the R software environment.
# Copyright (C) 2021 Colorado School of Mines
# 1500 Illinois St., Golden, CO 80401
# Contact: Douglas Nychka,  douglasnychka@gmail.edu,
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the R software environment if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# or see http://www.r-project.org/Licenses/GPL-2
##END HEADER


suppressMessages(library(fields))
options(echo=FALSE)
test.for.zero.flag<- 1

data(ozone2)

x<- ozone2$lon.lat
y<- ozone2$y[16,]

temp<- Rad.cov( x,x, p=2)
temp2<- RadialBasis( rdist( x,x), M=2, dimension=2)

temp3<-  rdist( x,x)
temp3 <- ifelse( abs(temp3) < 1e-14, 0,log( temp3)*(temp3^2) )
temp3<- radbas.constant( 2,2)*temp3

test.for.zero( temp, temp2, tag="Tps radial basis function 2d")
test.for.zero( temp, temp3, tag="Tps radial basis function 2d")
test.for.zero( temp2,temp3, tag="Tps radial basis function 2d")


set.seed( 123)
xtemp<- matrix( runif( 40*3), ncol=3) 
temp<- Rad.cov( xtemp,xtemp, p= 2*4-3)
temp2<- RadialBasis( rdist( xtemp,xtemp), M=4, dimension=3)

temp3<-  rdist( xtemp,xtemp)
temp3 <- ifelse( abs(temp3) < 1e-14, 0, temp3^(2*4 -3) )
temp3<- radbas.constant( 4,3)*temp3

test.for.zero( temp, temp2, tag="Tps radial basis function 3d")
test.for.zero( temp, temp3, tag="Tps radial basis function 3d")
test.for.zero( temp2,temp3, tag="Tps radial basis function 3d")

#### testing multiplication of a vector
#### mainly to make the FORTRAN has been written correctly
#### after replacing the ddot call with an explicit  do loop
set.seed( 123)
C<- matrix( rnorm( 10*5),10,5 )
x<- matrix( runif( 10*2), 10,2)
temp3<- rdist( x,x)
K<-  ifelse( abs(temp3) < 1e-14, 0,log( temp3)*(temp3^2) )
K<- K * radbas.constant( 2,2)
test.for.zero( Rad.cov( x,x,m=2, C=C) , K%*%C, tol=1e-10)

set.seed( 123)
C<- matrix( rnorm( 10*5),10,5 )
x<- matrix( runif( 10*3), 10,3)
temp3<- rdist( x,x)
K<-  ifelse( abs(temp3) < 1e-14, 0,(temp3^(2*4-3)) )
K<- K * radbas.constant( 4,3)
test.for.zero( Rad.cov( x,x,m=4, C=C) , K%*%C,tol=1e-10)


#####  testing derivative formula

set.seed( 123)
C<- matrix( rnorm( 10*1),10,1 )
x<- matrix( runif( 10*2), 10,2)
temp0<-  Rad.cov( x,x, p=4, derivative=1, C=C)

eps<- 1e-6
temp1<- (
           Rad.cov( cbind(x[,1]+eps, x[,2]),x, p=4, derivative=0, C=C) 
         - Rad.cov( cbind(x[,1]-eps, x[,2]),x, p=4, derivative=0, C=C) )/ (2*eps)
temp2<- (
           Rad.cov( cbind(x[,1], x[,2]+eps),x, p=4, derivative=0, C=C) 
         - Rad.cov( cbind(x[,1], x[,2]-eps),x , p=4,derivative=0,C=C) )/ (2*eps)

test.for.zero( temp0[,1], temp1, tag=" der of Rad.cov", tol=1e-6)
test.for.zero( temp0[,2], temp2, tag=" der of Rad.cov", tol=1e-6)



# comparing  Rad.cov used by Tps with simpler function called 
# by stationary.cov
set.seed( 222)
x<- matrix( runif( 10*2), 10,2)
C<- matrix( rnorm( 10*3),10,3 ) 
temp<- Rad.cov( x,x, p=2, C=C)
temp2<- RadialBasis( rdist( x,x), M=2, dimension=2)%*%C
test.for.zero( temp, temp2)

#### Basic matrix form for Tps as sanity check
x<- ChicagoO3$x
y<- ChicagoO3$y

obj<-Tps( x,y, scale.type="unscaled", with.constant=FALSE)

# now work out the matrix expressions explicitly
lam.test<- obj$lambda
N<-length(y)

Tmatrix<- cbind( rep( 1,N), x)
D<- rdist( x,x)
R<- ifelse( D==0, 0, D**2 * log(D))
A<- rbind(
          cbind( R+diag(lam.test,N), Tmatrix),
          cbind( t(Tmatrix), matrix(0,3,3)))

 hold<-solve( A, c( y, rep(0,3)))
 c.coef<- hold[1:N]
 d.coef<- hold[ (1:3)+N]
 zhat<-  R%*%c.coef + Tmatrix%*% d.coef
  test.for.zero( zhat, obj$fitted.values, tag="Tps 2-d m=2 sanity check")
# out of sample prediction
xnew<- rbind( c( 0,0),
              c( 10,10)
              )
T1<- cbind( rep( 1,nrow(xnew)), xnew)
D<- rdist( xnew,x)
R1<- ifelse( D==0, 0, D**2 * log(D))
z1<-  R1%*%c.coef + T1%*% d.coef
  test.for.zero( z1, predict( obj, x=xnew), tag="Tps 2-d m=2 sanity predict")

#### test Tps verses Krig note scaling must be the same
   out<- Tps( x,y)
   out2<- Krig( x,y, Covariance="RadialBasis", 
           M=2, dimension=2, scale.type="range", method="GCV")
   test.for.zero( predict(out), predict(out2), tag="Tps vs.  Krig w/ GCV")

# test for fixed lambda
   test.for.zero( 
   predict(out,lambda=.1), predict(out2, lambda=.1),
   tag="Tps vs. radial basis w Krig")

#### testing derivative using predict function 
   set.seed( 233)
   x<- matrix( (rnorm( 1000)*2 -1), ncol=2)
   y<- (x[,1]**2 + 2*x[,1]*x[,2] -  x[,2]**2)/2

   out<- Tps( x, y, scale.type="unscaled")

   xg<- make.surface.grid( list(x=seq(-.7,.7,,10),  y=seq(-.7,.7,,10)) )
   test<- cbind( xg[,1] + xg[,2], xg[,1] - xg[,2])
#   test<- xg
   look<- predictDerivative.Krig( out, x= xg) 
   test.for.zero( look[,1], test[,1], tol=1e-3)
   test.for.zero( look[,2], test[,2], tol=1e-3)

# matplot( test, look, pch=1)

options( echo=TRUE)
cat("all done testing Tps", fill=TRUE)

 

