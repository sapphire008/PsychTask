function cirobj = ActiveCreateCircleObject(scrX,scrY,location,gamble,angle)
    
    %cirobj.outcome = outcome;
    cirobj.gamble = gamble;
    
    cirobj.diameter = 0.20*scrX;
    if location == 1
        cirobj.startY = (2*scrY/7)-cirobj.diameter/2;
    elseif location == 2
        cirobj.startY = (5*scrY/7)-cirobj.diameter/2;
    end
    cirobj.startX = (scrX-cirobj.diameter)/2;
    cirobj.endX = cirobj.startX+cirobj.diameter;
    cirobj.endY = cirobj.startY+cirobj.diameter;
    
    cirobj.linewidth = 4;
    cirobj.linecolor = 225;
    cirobj.wincolor = [200 200 0];
    
    cirobj.position = [cirobj.startX cirobj.startY cirobj.endX cirobj.endY];
    cirobj.degree = angle;
    cirobj.startframe = 270;
    
    cirobj.lineY = sind(mod(cirobj.startframe-cirobj.degree/2,360))*cirobj.diameter/2;
    cirobj.lineX = cosd(mod(cirobj.startframe-cirobj.degree/2,360))*cirobj.diameter/2;
    cirobj.line2Y = sind(mod(cirobj.startframe+cirobj.degree/2,360))*cirobj.diameter/2;
    cirobj.line2X = cosd(mod(cirobj.startframe+cirobj.degree/2,360))*cirobj.diameter/2;
    
end