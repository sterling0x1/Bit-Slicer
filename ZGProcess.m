/*
 * Created by Mayur Pawashe on 10/28/09.
 *
 * Copyright (c) 2012 zgcoder
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ZGProcess.h"

@implementation ZGProcess

static NSArray *frozenProcesses = nil;
+ (NSArray *)frozenProcesses
{
	if (!frozenProcesses)
	{
		frozenProcesses = [[NSArray alloc] init];
	}
	
	return frozenProcesses;
}

+ (void)addFrozenProcess:(pid_t)pid
{
	frozenProcesses = [frozenProcesses arrayByAddingObject:@(pid)];
}

+ (void)removeFrozenProcess:(pid_t)pid
{
	NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
	
	for (NSNumber *currentPID in frozenProcesses)
	{
		if (currentPID.intValue != pid)
		{
			[mutableArray addObject:currentPID];
		}
	}
	
	frozenProcesses = [NSArray arrayWithArray:mutableArray];
}

+ (void)pauseOrUnpauseProcess:(pid_t)pid
{
	BOOL success;
	
	if ([ZGProcess.frozenProcesses containsObject:@(pid)])
	{
		// Unfreeze
		success = ZGUnpauseProcess(pid);
		
		if (success)
		{
			[ZGProcess removeFrozenProcess:pid];
		}
	}
	else
	{
		// Freeze
		success = ZGPauseProcess(pid);
		
		if (success)
		{
			[ZGProcess addFrozenProcess:pid];
		}
	}
}

- (id)initWithName:(NSString *)processName processID:(pid_t)aProcessID set64Bit:(BOOL)flag64Bit
{
	if ((self = [super init]))
	{
		self.name = processName;
		self.processID = aProcessID;
		self.is64Bit = flag64Bit;
	}
	
	return self;
}

- (void)dealloc
{
	self.processTask = MACH_PORT_NULL;
}

- (void)setProcessTask:(ZGMemoryMap)newProcessTask
{
	if (_processTask)
	{
		ZGFreeTask(_processTask);
	}
	
	_processTask = newProcessTask;
}

- (int)numberOfRegions
{
	return ZGNumberOfRegionsForProcessTask(self.processTask);
}

- (BOOL)grantUsAccess
{
	ZGMemoryMap newProcessTask = MACH_PORT_NULL;
	BOOL success = ZGGetTaskForProcess(self.processID, &newProcessTask);
	if (success)
	{
		self.processTask = newProcessTask;
	}
	
	return success;
}

- (BOOL)hasGrantedAccess
{
    return (self.processTask != MACH_PORT_NULL);
}

- (ZGMemorySize)pointerSize
{
	return self.is64Bit ? sizeof(int64_t) : sizeof(int32_t);
}

@end
