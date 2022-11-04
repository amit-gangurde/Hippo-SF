public class CustomIteratorString implements Iterator<String>{
 
   private List<String> obj;
   private Integer currentIndex;
   private Integer temp;
   public CustomIteratorString(List<String> obj){
       this.obj = obj;
       this.currentIndex = 0;
   }
 
   public boolean hasNext(){ 
       if( obj!=null &&  obj.size()>0){
       return currentIndex < obj.size()-1;
       }else{
         return false;  
       }
   }    
 
   public String next(){
       if(hasNext()) {
           temp = currentIndex;
           currentIndex++;
           return obj[temp];
       } else {
           throw new NoSuchElementException();
       }
   } 
}