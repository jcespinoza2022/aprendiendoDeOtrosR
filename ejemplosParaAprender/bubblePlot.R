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
bubblePlot <-  function( x, y, z, 
                      col = viridis::viridis(256),
                      zlim = NULL,
                      horizontal = FALSE,
                      legend.cex = 1.0,
                      legend.lab = NULL,
                      legend.line= 2, 
                      legend.shrink = 0.9, 
                      legend.width = 1.2, 
                      legend.mar = ifelse(horizontal, 3.1, 5.1),
                      axis.args = NULL, 
                      legend.args = NULL,
                      size=1.0,
                      add=FALSE,
                      legendLayout=NULL,
                      highlight=TRUE,
                      highlight.color="grey30",
                      ...){
  # NOTE: need to use
  # when just adding points to a plot 
  #  add=TRUE
  
  # use setupLegend before plotting to 
  # include a legend color scales
  # adjust values of x,y, and z if (x,y) passed in first argument
   x<- as.matrix( x)
  if( dim(x)[2]==2){
    z<- y 
    y<- x[,2]
    x<- x[,1]
  }
# color table for z  values  
  ctab= color.scale( z, col, zlim=zlim)
  
  
# setup space for a legend if needed  
  if(!add  & is.null(legendLayout) ){
    legendLayout<- setupLegend( 
       legend.shrink = legend.shrink, 
        legend.width = legend.width ,
          legend.mar = legend.mar, 
          horizontal = horizontal
       ) 
  } 
  
  if( !add){
    plot( x,y, col=ctab, cex=size, pch=16, ...) 
  }
  else{
 # just add points to an existing plot
  points( x,y, cex=size, col=ctab, pch=16, ...)
  }
# add a circle around points   
  if(highlight){
    points( x, y, cex=size, col=highlight.color)
  } 
  
# save current graphics settings  
  big.par <- par(no.readonly = TRUE)
  mfg.save <- par()$mfg
  
# add legend  
if( !add | !is.null(legendLayout)){ 
   levelsZ<- attr(ctab,"levelsZ")
    if((is.null(axis.args))&(!is.null(levelsZ))){
      axis.args= list(at= 1: length( levelsZ) , labels= levelsZ)
    }
#
    print( legend.args)
    addLegend( legendLayout, 
      col = attr(ctab,"col"), 
      #zlim = range(z, na.rm=TRUE),
      zlim= attr(ctab,"zlim"),
      axis.args = axis.args, 
      legend.args = legend.args,
              legend.cex = legend.cex,
              legend.lab = legend.lab,
              legend.line = legend.line
              )
}
  
# return to graphics setting of the scatterplot  
# so more good stuff can be added ...
  par(plt = big.par$plt, xpd = FALSE)
  par(mfg = mfg.save, new = FALSE)
  
}

