function [Y1,Y2] = regularization(X1,X2,tau,mu,W,type)


    q = [1, 1.5, 3, 6, 9, 12, 15, 18]';
    Wr = q*W;

    
if strcmp(type,'l2_reg')
    
    Y1 = (mu*X1)./(mu + tau*Wr);
    Y2 = (mu*X2)./(mu + tau*Wr);
        
end

