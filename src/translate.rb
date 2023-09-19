class Translator

    # inner class that represents a word
    class Word
      def initialize(pos,translations)
        @pos =  pos
        @translations = translations
      end
      #getter
      def getPos
        @pos
      end
      #setter
      def setPos(pos)
        @pos = pos
      end
      # instead could use 
      # attr_accessor :pos
  
      #getter
      def getTranslations
        @translations
      end
      #setter
      def setTranslations(lang,newTrans)
        @pos[lang] = newTrans
      end
      #instead could use
      #attr_accessor : translations
    end
  
    #initializes the data structures by reading in the input from the word and grammar files
    def initialize(words_file, grammar_file)
      @wordData = []
      @library = {}
      index = 0
      @grammarStructs = {}
      
      updateLexicon(words_file)
      updateGrammar(grammar_file)
    end
  
      # part 1
    
      #updates the data structure storing information about each word
      def updateLexicon(inputfile)
        
        index = @wordData.length
        
        #reading the Language file and initializing the data structures
        wf = File.open(inputfile)
        line = wf.gets    #reads a line in the file
        
        while line
          line.chomp!
          seperateLine = line.split(", ")
          transHash = {}
  
          #check if the line has a valid format
          if seperateLine.length > 2
            #examine if the engl word is all loweracase or contains "-"
            if seperateLine[0] =~ /^([a-z\-]+)$/
              englWord = seperateLine[0]
              transHash["English"] = englWord
            end
            #check for if (POS) the string is any capitalized 3 letter code
            if seperateLine[1] =~ /^([A-Z]{3})$/
              poSpeech = seperateLine[1]
            end
  
            for i in 2..seperateLine.length-1
              seperateTrans = seperateLine[i].split(":")
              if seperateTrans.length == 2
                #check if the language starts with an uppercase char and is followed by lowercase alphanumeric chars
                if seperateTrans[0] =~ /^[A-Z][a-z0-9]+$/
                  #check if the translated word contains only lowercase chars and the hyphen
                  #maybe make private method for checking words
                  if seperateTrans[1] =~ /^([a-z\-]+)$/
                    transHash[seperateTrans[0]] = seperateTrans[1]
                  end
                end
              else
                i = seperateTrans.length-1
                transHash = nil
              end
            end
  
            #if the line is valid, add it to the word array
            if transHash != nil && transHash.length > 1
              @wordData[index] = Word.new(poSpeech,transHash)
              wordHash = @wordData[index].getTranslations
  
              for langKey in wordHash.keys
                #check if the key and wordHash[key] already exist in the library
                word = wordHash[langKey]
  
                if @library[langKey]
                  if @library[langKey][word]
                      #get the length of the inner array (that is a hash value)
                      innerIndex = @library[langKey][word].length
                      @library[langKey][word][innerIndex] = index
                  else
                      @library[langKey][word] = []
                      @library[langKey][word][0] = index
                  end
                else
                  @library[langKey] = {}
                  @library[langKey][word] = []
                  @library[langKey][word][0] = index
                end
              end
  
              index += 1
            end
  
          end
  
          line = wf.gets
        end 
        wf.close
  
      end
    
      #updates the data structure storing information about each language and its POS order
      def updateGrammar(inputfile)
        
        fd = File.open(inputfile)
        line = fd.gets    #reads a line in the file
        while line
          line.chomp!
          splitLine = line.split(": ")
  
          if splitLine.length > 1
            #check formatting for the language specified
            if splitLine[0] =~ /^[A-Z][a-z0-9]+$/
              splitPOS = splitLine[1].split(", ")
              posOrder = []
              posIndex = 0
              #check formatting for the POS'
              for i in 0..splitPOS.length-1
                if splitPOS[i] =~ /^([A-Z]{3})$/  #adds the POS to the array
                  posOrder[posIndex] = splitPOS[i]
                  posIndex += 1
                elsif splitPOS[i].match(/^([A-Z]{3})\{([0-9]+)\}/)  #handles modifiers/repeated POS
                  groups = splitPOS[i].match(/^([A-Z]{3})\{([0-9]+)\}/)
                  for j in 1..(groups[2].to_i)
                    posOrder[posIndex] = groups[1]
                    posIndex += 1
                  end
                else
                  posOrder = nil
                  break;
                end
              end
  
              if posOrder != nil
                @grammarStructs[splitLine[0]] = posOrder
              end
  
            end
          end
  
        line = fd.gets
        end
        fd.close
      end
  
      # part 2
      #creates a sentence in the specified language given the specified POS format
      def generateSentence(language, struct)
        #if struct is a string, locate the format of the specified language
        if struct.class == String
          struct = @grammarStructs[struct]
        end
        if struct == nil
          return nil
        end
  
        sentence = ""
        #iterate through the struct
        for i in 0..struct.length-1
          origLength = sentence.length
          #iterate through the word data array until a word is found with the matching language and part of speech
          for j in 0..@wordData.length-1
            found = false
            if @wordData[j].getPos == struct[i]
  
              #iterate through the word object hash to find if the langages match
              hashExamine = @wordData[j].getTranslations
              for key in hashExamine.keys
                if key == language  #then use the associated word, which is its value pair
                  sentence += "#{hashExamine[key]} "
                  found = true 
                  break
                end
              end
            end
            #if a word is found that has a matching POS and language
            if found
              break
            end
          end
          if(sentence.length == origLength)
            return nil
          end
        end
        #return completed sentence
        sentence.rstrip
      end
    
      #checks if the sentence has the correct POS format specified
      def checkGrammar(sentence, language)
        posOrder = @grammarStructs[language]
        #split the sentence and the string of POS order into arrays
        splitSentence = sentence.split(" ")
        
        #check if the length of the sentence and array are the same
        if splitSentence.length == posOrder.length
          #iterate over the words in the sentence
          for i in 0..splitSentence.length-1
            #locate the words POS, first find the correct word index in the library hash
            indexArr = @library[language][splitSentence[i]]
            match = true
            #iterate over the index array and examine the word object at each index
            for j in 0..indexArr.length-1
              #check if the POS of the word matches
              if @wordData[indexArr[j]].getPos == posOrder[i]
                match = true
                break;
              else
                match = false
              end
            end
            #if the POS of the word doesn't match
            if !match
              return false
            end
          end
          return true
        end
        return false
      end
    
      #given a sentence formatted by struct1, rearrange the sentence so that its grammar format
      #is that of struct2
      def changeGrammar(sentence, struct1, struct2)
        #check if sentence is valid
        if sentence.length == 0
          return nil
        end
        
        #check if struct1 is a language name, if so find its POS order
        if struct1.class == String
          struct1 = @grammarStructs[struct1]
          #check if struct1 is valid
          if struct1 == nil
            return nil
          end
        end
  
        if struct2.class == String
          struct2 = @grammarStructs[struct2]
          #check if struct2 is valid
          if struct2 == nil
            return nil
          end
        end
        
        splitSentence = sentence.split(" ")
        #create a hash that links each word in the sentence to the POS from the original structure
        #simultaneously check if each POS from the original structure is in the new structure
        origFormat = {}
        for i in 0..splitSentence.length-1
          #check if all of struct1's POS' match those in struct2's POS structure
          if struct2.include?(struct1[i])
            if origFormat[struct1[i]]
              origFormat[struct1[i]][origFormat[struct1[i]].length] = splitSentence[i]
            else
              origFormat[struct1[i]] = []
              origFormat[struct1[i]][0] = splitSentence[i]
            end
  
          else
            return nil
          end
          
        end
  
        sentence = ""
        #iterate through struct2's structure
        for i in 0..struct2.length-1
          #check if all of struct2's POS' match those in struct1's POS structure
          if origFormat.has_key?(struct2[i])
            #if the POS' match, add its associated word (value pair) to the sentence
            word = origFormat[struct2[i]][0]
            sentence += "#{word} "
            origFormat[struct2[i]].shift
          else
            return nil
          end
        end
        sentence.rstrip
  
      end
  
      # part 3
    
      #given a sentence in a specified language, change the sentence into the second language passed in
      def changeLanguage(sentence, language1, language2)
        #split the sentence and store language1's POS structure
        splitSentence = sentence.split(" ")
        langStructure = @grammarStructs[language1]
        sentence = ""
  
        #iterate through the split sentence to find each associated word index
        for i in 0..splitSentence.length-1
          #check if the language and word from the sentence is valid
          if @library.has_key?(language1)
            if @library[language1].has_key?(splitSentence[i])
              wordIndex = @library[language1][splitSentence[i]]
              #iterate through the word index array to find the correct translation associated with POS
              for j in 0..wordIndex.length-1
                if @wordData[wordIndex[j]].getPos == langStructure[i]
                  found = false
                  #iterate through the word object's hash to find the translated version of language2
                  hashExamine = @wordData[wordIndex[j]].getTranslations
                  for key in hashExamine.keys
                    if key == language2
                      sentence += "#{hashExamine[key]} "
                      found = true;
                      break;
                    end
                  end
                  #if the associated translated word in language2 isn't found return nil
                  if !found
                    return nil
                  end
                end
                break;
              end
            else
              return nil
            end
          else
            return nil
          end
        end
        #if a the sentence is created in language2
        sentence.rstrip
      end
      
      #given a sentence in language1, create a new sentence to be in language2 grammar
      #format and change it into language2
      def translate(sentence, language1, language2)
        sentence = changeLanguage(sentence,language1,language2)
        #check if there was an error with changing language
        if sentence == nil
          return nil
        else
          #store lang1 POS structure into an array
          lang1Structure = @grammarStructs[language1]
          sentence = changeGrammar(sentence,lang1Structure,language2)
          #check if there was an error with changing the grammar
          if sentence == nil
            return nil
          else
            return sentence
          end
        end
        return nil
      end
    end  
  
  
  transObj = Translator.new("../public/inputs/words1.txt","../public/inputs/grammar1.txt")
  puts transObj.changeGrammar("I am Ryan", ["Pos1","Pos1","Pos3"], ["Pos1","Pos3","Pos1"])
  =begin
  transObj = Translator.new("../public/inputs/words1.txt","../public/inputs/grammar1.txt")
  puts "--------------------"
  transObj.updateLexicon("../public/inputs/words2.txt")
  transObj.updateGrammar("../public/inputs/grammar2.txt")
  puts "--------------------"
  transObj.updateLexicon("../public/inputs/words3.txt")
  transObj.updateGrammar("../public/inputs/grammar3.txt")
  puts "--------------------"
  =end
  
  puts transObj.generateSentence("English","English")
  puts transObj.checkGrammar("el camion azul","Spanish")
  =begin
  #puts transObj.changeGrammar("el azul camion", "English", ["DET", "NOU", "ADJ"])
  #puts transObj.changeGrammar("the blue truck", "English", "English")
  puts transObj.changeGrammar("bleu mer le", "French", ["DET","ADJ","NOU"])
  puts transObj.changeLanguage("the blue truck", "English", "French") #continue testing this later
  puts transObj.translate("the blue sea", "English", "French")
  =end